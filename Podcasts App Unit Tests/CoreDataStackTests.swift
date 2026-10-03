import CoreData
import XCTest
@testable import Podcasts_Bin

final class CoreDataStackTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("CoreDataStackTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func test_model_keysFavoritesByFeedAndHistoryByStreamUrl() throws {
        let entities = CoreDataStack.model.entitiesByName
        let favorite = try XCTUnwrap(entities[FavoritePodcastEntity.entityName])
        let history = try XCTUnwrap(entities[HistoryEpisodeEntity.entityName])
        XCTAssertEqual(favorite.uniquenessConstraints as? [[String]], [["rssFeedUrl"]])
        XCTAssertEqual(history.uniquenessConstraints as? [[String]], [["streamUrl"]])
        XCTAssertEqual(favorite.managedObjectClassName, NSStringFromClass(FavoritePodcastEntity.self))
        XCTAssertEqual(history.managedObjectClassName, NSStringFromClass(HistoryEpisodeEntity.self))
    }

    func test_store_keepsFavoritesAndHistoryAcrossLaunches() async throws {
        let storeURL = directory.appendingPathComponent("Podcasts.sqlite")
        let api = APIService(session: URLSession(configuration: .ephemeral))
        try await PodcastsRepository(api: api, store: CoreDataStack(storeURL: storeURL)).favorite(podcast: makePodcast())
        try await EpisodesRepository(api: api, store: CoreDataStack(storeURL: storeURL)).saveInHistory(episode: makeEpisode("1"))

        let relaunched = CoreDataStack(storeURL: storeURL)
        let favorites = try await PodcastsRepository(api: api, store: relaunched).fetchFavoritePodcasts()
        let history = try await EpisodesRepository(api: api, store: relaunched).fetchHistory()
        XCTAssertEqual(favorites.map(\.rssFeedUrl), ["https://example.com/feed"])
        XCTAssertEqual(history.map(\.streamUrl), ["https://example.com/1.mp3"])
    }

    func test_insertingTheSameEpisodeTwice_keepsOneRow() async throws {
        let stack = CoreDataStack(inMemory: true)
        for title in ["First", "Second"] {
            try await stack.perform { context in
                let entity = HistoryEpisodeEntity(context: context)
                entity.update(from: makeEpisode("1", title: title))
                entity.lastPlayedAt = Date()
            }
        }

        let titles = try await stack.perform { context in
            try context.fetch(HistoryEpisodeEntity.allRequest()).map(\.title)
        }
        XCTAssertEqual(titles, ["Second"])
    }
}
