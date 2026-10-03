import XCTest
@testable import Podcasts_Bin

final class ItemViewModelTests: XCTestCase {
    func test_episodeViewModel_carriesEveryDetailBothWays() {
        var original = makeEpisode("1", podcastFeedUrl: "https://example.com/feed")
        original.fileUrl = "https://cdn.example.com/1.mp3"

        let viewModel = EpisodeViewModel(episode: original)
        let roundTripped = Episode(episodeViewModel: viewModel)

        XCTAssertEqual(viewModel.podcastFeedUrl, "https://example.com/feed")
        XCTAssertEqual(roundTripped.streamUrl, original.streamUrl)
        XCTAssertEqual(roundTripped.title, original.title)
        XCTAssertEqual(roundTripped.pubDate, original.pubDate)
        XCTAssertEqual(roundTripped.fileUrl, original.fileUrl)
        XCTAssertEqual(roundTripped.imageUrl, original.imageUrl)
        XCTAssertEqual(roundTripped.podcastFeedUrl, original.podcastFeedUrl)
    }

    func test_podcastViewModel_carriesEveryDetailBothWays() {
        let original = makePodcast("https://example.com/feed", title: "Show", totalEpisodes: 7)

        let viewModel = PodcastViewModel(podcast: original)
        let roundTripped = Podcast(podcastViewModel: viewModel)

        XCTAssertEqual(viewModel.numberOfEpisodes, "7 episodes")
        XCTAssertEqual(roundTripped, original)
        XCTAssertEqual(roundTripped.recordId, original.recordId)
    }
}
