import AVFoundation
import SwiftUI
import UIKit
import XCTest
@testable import Podcasts_Bin

@MainActor
final class PlayerDetailsViewTests: XCTestCase {
    private static var retainedObjects: [AnyObject] = []

    private func episode(_ id: String) -> Episode {
        Episode(title: "An episode with a fairly long title that wraps onto more than one line, \(id)",
                subtitle: "", pubDate: Date(timeIntervalSinceReferenceDate: 0), description: "",
                author: "A Podcast Author With A Long Name", streamUrl: "file:///private/tmp/player-layout-test-\(id).wav")
    }

    /// Lays the player out at the given size and returns its scroll view.
    private func layOutPlayer(width: CGFloat, height: CGFloat, size: ContentSizeCategory) throws -> UIScrollView {
        let suite = "PlayerDetailsViewTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let player = AVPlayer()
        let playback = PlaybackManager(player: player, defaults: defaults, systemPlaybackEnabled: false, saveHistory: { _ in })
        let viewModel = PlayerViewModel(playback: playback)
        Self.retainedObjects.append(player)
        Self.retainedObjects.append(playback)
        // A second episode in the queue makes the player show its Up Next card too.
        let current = episode("current")
        playback.load(current, queue: [current, episode("next")], autoplay: false)

        let host = UIHostingController(rootView: PlayerDetailsView {}
            .environmentObject(viewModel)
            .environment(\.sizeCategory, size))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = host
        window.makeKeyAndVisible()
        Self.retainedObjects.append(window)
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        host.view.layoutIfNeeded()

        func find(_ view: UIView) -> UIScrollView? {
            if let scrollView = view as? UIScrollView { return scrollView }
            return view.subviews.lazy.compactMap(find).first
        }
        return try XCTUnwrap(find(host.view), "PlayerDetailsView should contain a scroll view")
    }

    func test_playerContent_neverScrollsHorizontally() throws {
        let sizes: [ContentSizeCategory] = [.large, .extraExtraExtraLarge, .accessibilityLarge, .accessibilityExtraExtraExtraLarge]
        for width in [320.0, 375.0, 393.0] {
            for size in sizes {
                let scrollView = try layOutPlayer(width: width, height: 700, size: size)
                // Check against the screen, not the scroll view: an overflowing row widens both together.
                XCTAssertLessThanOrEqual(scrollView.bounds.width, width + 0.5,
                                         "Player is wider than the screen at width \(width), text size \(size)")
                XCTAssertLessThanOrEqual(scrollView.contentSize.width, width + 0.5,
                                         "Player content is wider than the screen at width \(width), text size \(size)")
            }
        }
    }
}
