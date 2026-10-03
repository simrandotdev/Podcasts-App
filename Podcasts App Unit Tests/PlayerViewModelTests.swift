import AVFoundation
import XCTest
@testable import Podcasts_Bin

@MainActor
final class PlayerViewModelTests: XCTestCase {
    /// AVPlayer finishes configuring asynchronously and crashes if released immediately.
    private static var retainedObjects: [AnyObject] = []

    private func withPlayer(_ body: (PlayerViewModel, PlaybackManager) throws -> Void) rethrows {
        let suite = "PlayerViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let player = AVPlayer()
        let playback = PlaybackManager(player: player, defaults: defaults, systemPlaybackEnabled: false, saveHistory: { _ in })
        Self.retainedObjects += [player, playback]
        defer {
            playback.close()
            defaults.removePersistentDomain(forName: suite)
        }
        try body(PlayerViewModel(playback: playback), playback)
    }

    private func episode(_ id: String, feed: String? = "https://example.com/a", author: String = "Author") -> EpisodeViewModel {
        EpisodeViewModel(episode: Episode(title: "Episode \(id)", subtitle: "", pubDate: Date(timeIntervalSinceReferenceDate: 0),
                                          description: "", author: author,
                                          streamUrl: "file:///private/tmp/player-view-model-test-\(id).wav",
                                          podcastFeedUrl: feed))
    }

    private func podcast(feed: String, author: String = "Author") -> PodcastViewModel {
        PodcastViewModel(title: "Show", author: author, image: "", totalEpisodes: 1, rssFeedUrl: feed)
    }

    // MARK: - Playing

    func test_play_loadsTheEpisodeWithItsQueue() {
        let first = episode("first"), second = episode("second")
        withPlayer { sut, _ in
            sut.play(first, queue: [first, second])
            XCTAssertEqual(sut.episode?.streamUrl, first.streamUrl)
            XCTAssertEqual(sut.queue.map(\.streamUrl), [first.streamUrl, second.streamUrl])
            XCTAssertEqual(sut.upNext?.streamUrl, second.streamUrl)
            XCTAssertTrue(sut.isPlaying)
        }
    }

    func test_play_resumesTheLoadedEpisodeWithoutReloading() {
        let first = episode("first"), other = episode("other")
        withPlayer { sut, playback in
            playback.load(Episode(episodeViewModel: first), queue: [Episode(episodeViewModel: first)], autoplay: false)
            sut.seek(to: 30)

            sut.play(first, queue: [other])

            XCTAssertEqual(sut.currentTime, 30)
            XCTAssertEqual(sut.queue.map(\.streamUrl), [first.streamUrl])
            XCTAssertTrue(sut.isPlaying)
        }
    }

    func test_errorMessage_canBeDismissed() {
        let first = episode("first")
        var invalid = Episode(episodeViewModel: episode("invalid"))
        invalid.fileUrl = "invalid-scheme://audio"
        withPlayer { sut, playback in
            sut.play(first, queue: [first])
            sut.play(EpisodeViewModel(episode: invalid), queue: [])
            XCTAssertNotNil(sut.errorMessage)
            sut.errorMessage = nil
            XCTAssertNil(playback.errorMessage)
            XCTAssertEqual(sut.episode?.streamUrl, first.streamUrl)
        }
    }

    // MARK: - ON AIR

    func test_isOnAir_matchesThePlayingPodcastByFeedUrlNotAuthor() {
        let playing = episode("on-air", feed: "https://example.com/a", author: "Shared Network")
        withPlayer { sut, _ in
            sut.play(playing, queue: [playing])
            XCTAssertTrue(sut.isOnAir(podcast(feed: "https://example.com/a", author: "Someone Else")))
            XCTAssertFalse(sut.isOnAir(podcast(feed: "https://example.com/b", author: "Shared Network")))
            XCTAssertTrue(sut.isOnAir(playing))
        }
    }

    func test_isOnAir_isFalseWhenPaused() {
        let playing = episode("on-air")
        withPlayer { sut, _ in
            sut.play(playing, queue: [playing])
            sut.pause()
            XCTAssertFalse(sut.isOnAir(podcast(feed: "https://example.com/a")))
            XCTAssertFalse(sut.isOnAir(playing))
        }
    }

    func test_isOnAir_isFalseForLegacyEpisodesWithoutFeedUrl() {
        let legacy = episode("legacy", feed: nil)
        withPlayer { sut, _ in
            sut.play(legacy, queue: [legacy])
            XCTAssertFalse(sut.isOnAir(podcast(feed: "https://example.com/a")))
        }
    }

    func test_isOnAirWithEpisodes_matchesLegacyEpisodesByStreamUrl() {
        let legacy = episode("legacy", feed: nil)
        withPlayer { sut, _ in
            sut.play(legacy, queue: [legacy])
            XCTAssertTrue(sut.isOnAir(podcast(feed: "https://example.com/a"), episodes: [legacy]))
            XCTAssertFalse(sut.isOnAir(podcast(feed: "https://example.com/a"), episodes: [episode("other")]))
        }
    }
}
