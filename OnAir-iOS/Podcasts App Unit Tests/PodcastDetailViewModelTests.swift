import XCTest
@testable import Podcasts_Bin

@MainActor
final class PodcastDetailViewModelTests: XCTestCase {
    private var isolated: IsolatedManagers!
    private var podcasts: MockPodcastsManager!
    private var episodes: MockEpisodesManager!
    private let feed = "https://example.com/feed"
    private var clock = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private var feedEpisodes: [Episode] = []

    override func setUp() async throws {
        isolated = IsolatedManagers()
        podcasts = MockPodcastsManager()
        episodes = MockEpisodesManager()
    }

    override func tearDown() async throws {
        isolated.tearDown()
    }

    private func makeViewModel(downloads: DownloadManager? = nil,
                               newEpisodes: NewEpisodesManager? = nil) -> PodcastDetailViewModel {
        PodcastDetailViewModel(podcast: PodcastViewModel(podcast: makePodcast(feed)),
                               podcastsManager: podcasts, episodesManager: episodes,
                               downloadManager: downloads ?? isolated.downloadManager(),
                               newEpisodesManager: newEpisodes ?? isolated.newEpisodesManager())
    }

    func test_load_showsEpisodesAndFavoriteState() async {
        episodes.episodesByFeed[feed] = [makeEpisode("latest"), makeEpisode("older")]
        podcasts.favorites = [makePodcast(feed)]
        let sut = makeViewModel()

        await sut.load()

        XCTAssertEqual(sut.episodes.map(\.title), ["Episode latest", "Episode older"])
        XCTAssertEqual(sut.latestEpisode?.title, "Episode latest")
        XCTAssertTrue(sut.isFavorite)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_failedLoad_exposesErrorAndEndsLoading() async {
        episodes.shouldFail = true
        let sut = makeViewModel()

        await sut.load()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.episodes.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    func test_toggleFavorite_savesThenRemovesThePreset() async {
        let sut = makeViewModel()
        await sut.load()
        XCTAssertFalse(sut.isFavorite)

        await sut.toggleFavorite()
        XCTAssertTrue(sut.isFavorite)
        XCTAssertEqual(podcasts.favorites.map(\.rssFeedUrl), [feed])

        await sut.toggleFavorite()
        XCTAssertFalse(sut.isFavorite)
        XCTAssertTrue(podcasts.favorites.isEmpty)
        XCTAssertFalse(sut.isUpdatingFavorite)
    }

    func test_failedFavoriteChange_exposesErrorAndKeepsState() async {
        let sut = makeViewModel()
        podcasts.shouldFail = true

        await sut.toggleFavorite()

        XCTAssertFalse(sut.isFavorite)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isUpdatingFavorite)
    }

    func test_load_clearsThePodcastsNewEpisodes() async {
        let old = makeEpisode("old", pubDate: clock.addingTimeInterval(-86_400))
        feedEpisodes = [old]
        let newEpisodes = isolated.newEpisodesManager(favorites: { [unowned self] in [makePodcast(self.feed)] },
                                                      feeds: { [unowned self] _ in self.feedEpisodes },
                                                      now: { [unowned self] in self.clock })
        await newEpisodes.refresh()
        clock = clock.addingTimeInterval(3_600)
        feedEpisodes = [makeEpisode("new", pubDate: clock), old]
        clock = clock.addingTimeInterval(60)
        await newEpisodes.refresh()
        XCTAssertEqual(newEpisodes.newCount(for: feed), 1)
        episodes.episodesByFeed[feed] = feedEpisodes

        await makeViewModel(newEpisodes: newEpisodes).load()

        XCTAssertEqual(newEpisodes.newCount(for: feed), 0)
    }

    func test_load_identifiesEarlierDownloads() async throws {
        let episode = makeEpisode("downloaded")
        try isolated.storeUnidentifiedDownload(for: episode.streamUrl)
        let downloads = isolated.downloadManager()
        XCTAssertEqual(downloads.unidentifiedCount, 1)
        episodes.episodesByFeed[feed] = [episode]

        await makeViewModel(downloads: downloads).load()

        XCTAssertEqual(downloads.unidentifiedCount, 0)
        XCTAssertEqual(downloads.library.map(\.episode.title), ["Episode downloaded"])
    }
}
