import AVFoundation
import AVKit
import MediaPlayer
import UIKit
import XCTest
@testable import Podcasts_Bin

@MainActor
final class PlaybackControllerTests: XCTestCase {
    /// AVPlayer and MPNowPlayingSession finish configuring asynchronously and crash (KVO on a freed
    /// object) if released immediately, taking down whichever test runs next. Keep them alive.
    private static var retainedObjects: [AnyObject] = []

    private func makePlayer(_ item: AVPlayerItem? = nil) -> AVPlayer {
        let player = item.map(AVPlayer.init(playerItem:)) ?? AVPlayer()
        Self.retainedObjects.append(player)
        return player
    }

    func test_systemSession_publishesArtwork() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        var wav = Data()
        func text(_ value: String) { wav.append(Data(value.utf8)) }
        func word(_ value: UInt16) { var little = value.littleEndian; withUnsafeBytes(of: &little) { wav.append(contentsOf: $0) } }
        func integer(_ value: UInt32) { var little = value.littleEndian; withUnsafeBytes(of: &little) { wav.append(contentsOf: $0) } }
        let samples = Data(repeating: 0, count: 8000 * 2 * 30)
        text("RIFF"); integer(UInt32(samples.count + 36)); text("WAVEfmt "); integer(16)
        word(1); word(1); integer(8000); integer(16000); word(2); word(16)
        text("data"); integer(UInt32(samples.count)); wav.append(samples)
        try wav.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let item = AVPlayerItem(url: url)
        let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aT1sAAAAASUVORK5CYII=")!
        let image = try XCTUnwrap(UIImage(data: png))
        item.nowPlayingInfo = [MPMediaItemPropertyTitle: "Artwork regression fixture",
                               MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: image.size) { _ in image }]
        let player = makePlayer(item)
        let session = MPNowPlayingSession(players: [player])
        Self.retainedObjects.append(session)
        session.automaticallyPublishesNowPlayingInfo = true
        let target = session.remoteCommandCenter.playCommand.addTarget { _ in .success }
        try AVAudioSession.sharedInstance().setCategory(.playback)
        try AVAudioSession.sharedInstance().setActive(true)
        defer {
            player.pause()
            session.remoteCommandCenter.playCommand.removeTarget(target)
            try? AVAudioSession.sharedInstance().setActive(false)
        }
        player.play()
        for _ in 0..<50 {
            if session.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] != nil { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertNotNil(session.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork],
                        "Published metadata: \(String(describing: session.nowPlayingInfoCenter.nowPlayingInfo))")
    }

    private func episode(_ id: String, title: String = "Same title") throws -> EpisodeViewModel {
        let data = try JSONSerialization.data(withJSONObject: [
            "title": title, "subtitle": "", "pubDate": 0, "description": "", "author": "Author",
            "streamUrl": "file:///private/tmp/podcast-test-\(id).wav"
        ])
        return EpisodeViewModel(episode: try JSONDecoder().decode(Episode.self, from: data))
    }

    private func withPlayer(_ body: (PlaybackController, UserDefaults) throws -> Void) rethrows {
        let suite = "PlaybackControllerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let sut = PlaybackController(player: makePlayer(), defaults: defaults, systemPlaybackEnabled: false, saveHistory: { _ in })
        defer {
            sut.close()
            defaults.removePersistentDomain(forName: suite)
        }
        try body(sut, defaults)
    }

    func test_loadingEpisode_restoresLegacyPositionKey() throws {
        let first = try episode("first")
        try withPlayer { sut, defaults in
            defaults.set(125, forKey: first.streamUrl)
            sut.load(first, queue: [first], autoplay: false)
            XCTAssertEqual(sut.currentTime, 125)
            XCTAssertFalse(sut.isPlaying)
        }
    }

    func test_pausingAndPlaying_doesNotResetSeekPosition() throws {
        let first = try episode("first")
        withPlayer { sut, defaults in
            sut.load(first, queue: [first], autoplay: false)
            sut.seek(to: 82)
            sut.play()
            sut.pause()
            sut.play()
            XCTAssertEqual(sut.currentTime, 82)
            XCTAssertEqual(defaults.double(forKey: first.streamUrl), 82)
        }
    }

    func test_skipping_clampsNegativeAndIgnoresNonfinitePositions() throws {
        let first = try episode("first")
        withPlayer { sut, _ in
            sut.load(first, queue: [first], autoplay: false)
            sut.seek(to: 10)
            sut.skip(by: -15)
            XCTAssertEqual(sut.currentTime, 0)
            sut.skip(by: 15)
            sut.seek(to: .nan)
            sut.seek(to: .infinity)
            XCTAssertEqual(sut.currentTime, 15)
        }
    }

    func test_queue_identifiesEpisodesByURLWhenTitlesMatch() throws {
        let first = try episode("first")
        let second = try episode("second")
        withPlayer { sut, _ in
            sut.load(second, queue: [first, second], autoplay: false)
            XCTAssertTrue(sut.canPlayPrevious)
            XCTAssertFalse(sut.canPlayNext)
            sut.next()
            XCTAssertEqual(sut.episode?.streamUrl, second.streamUrl)
            sut.previous()
            XCTAssertEqual(sut.episode?.streamUrl, first.streamUrl)
            XCTAssertFalse(sut.canPlayPrevious)
            XCTAssertTrue(sut.canPlayNext)
        }
    }

    func test_switchingEpisodes_savesOutgoingAndRestoresIncomingPosition() throws {
        let first = try episode("first")
        let second = try episode("second")
        withPlayer { sut, defaults in
            defaults.set(40, forKey: second.streamUrl)
            sut.load(first, queue: [first, second], autoplay: false)
            sut.seek(to: 20)
            sut.load(second, queue: [first, second], autoplay: false)
            XCTAssertEqual(defaults.double(forKey: first.streamUrl), 20)
            XCTAssertEqual(sut.currentTime, 40)
        }
    }

    func test_close_savesProgressAndClearsPlayback() throws {
        let first = try episode("first")
        withPlayer { sut, defaults in
            sut.load(first, queue: [], autoplay: false)
            sut.seek(to: 35)
            sut.close()
            XCTAssertNil(sut.episode)
            XCTAssertTrue(sut.queue.isEmpty)
            XCTAssertFalse(sut.isPlaying)
            XCTAssertEqual(defaults.double(forKey: first.streamUrl), 35)
        }
    }

    func test_invalidURL_keepsCurrentEpisodeAndReportsError() throws {
        let first = try episode("first")
        let invalid = try episode("invalid")
        invalid.fileUrl = "invalid-scheme://audio"
        withPlayer { sut, _ in
            sut.load(first, queue: [], autoplay: false)
            sut.load(invalid, queue: [], autoplay: false)
            XCTAssertEqual(sut.episode?.streamUrl, first.streamUrl)
            XCTAssertNotNil(sut.errorMessage)
        }
    }

    func test_episodeSelection_recordsHistoryInSelectionOrder() async throws {
        let first = try episode("first")
        let second = try episode("second")
        let saved = expectation(description: "Both episodes saved")
        saved.expectedFulfillmentCount = 2
        var urls: [String] = []
        let sut = PlaybackController(player: makePlayer(), systemPlaybackEnabled: false) { episode in
            urls.append(episode.streamUrl)
            saved.fulfill()
        }
        sut.load(first, queue: [first, second], autoplay: false)
        sut.load(second, queue: [first, second], autoplay: false)
        await fulfillment(of: [saved], timeout: 2)
        XCTAssertEqual(urls, [first.streamUrl, second.streamUrl])
        sut.close()
    }

    func test_progress_isUnknownUntilDurationHasBeenLoaded() throws {
        let first = try episode("first")
        withPlayer { sut, defaults in
            defaults.set(30, forKey: first.streamUrl)
            XCTAssertNil(sut.progress(for: first))
        }
    }

    func test_progress_usesSavedPositionAndDuration() throws {
        let first = try episode("first")
        withPlayer { sut, defaults in
            defaults.set(30, forKey: first.streamUrl)
            defaults.set(120, forKey: "duration:" + first.streamUrl)
            XCTAssertEqual(sut.progress(for: first), 0.25)
        }
    }

    func test_progress_clampsPositionsBeyondTheDuration() throws {
        let first = try episode("first")
        withPlayer { sut, defaults in
            defaults.set(500, forKey: first.streamUrl)
            defaults.set(120, forKey: "duration:" + first.streamUrl)
            XCTAssertEqual(sut.progress(for: first), 1)
        }
    }

    func test_invalidDuration_isSafeForDisplay() {
        XCTAssertEqual(PlaybackController.validTime(.nan), 0)
        XCTAssertEqual(PlaybackController.validTime(.infinity), 0)
        XCTAssertEqual(PlaybackController.validTime(-10), 0)
        XCTAssertEqual(PlaybackController.validTime(12.5), 12.5)
    }
}
