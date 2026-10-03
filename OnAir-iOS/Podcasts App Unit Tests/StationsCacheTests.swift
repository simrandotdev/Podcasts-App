import XCTest
@testable import Podcasts_Bin

final class StationsCacheTests: XCTestCase {
    private var directory: URL!
    private var cache: StationsCache!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("StationsCacheTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        cache = StationsCache(fileURL: directory.appendingPathComponent("HomeStations.json"))
        StationsURLProtocol.status = 200
        StationsURLProtocol.body = #"{"results":[]}"#
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    // MARK: - Cache

    func test_savedStations_loadInOrderWithTheirDetails() {
        cache.save([makePodcast("https://example.com/b", title: "B", totalEpisodes: 3),
                    makePodcast("https://example.com/a", title: "A")])

        let stations = cache.load()

        XCTAssertEqual(stations.map(\.rssFeedUrl), ["https://example.com/b", "https://example.com/a"])
        XCTAssertEqual(stations.first?.title, "B")
        XCTAssertEqual(stations.first?.totalEpisodes, 3)
        XCTAssertEqual(stations.first?.image, "https://example.com/art.jpg")
    }

    func test_withoutAFile_noStationsLoad() {
        XCTAssertTrue(cache.load().isEmpty)
    }

    func test_unreadableFile_loadsNoStations() throws {
        try Data("not json".utf8).write(to: cache.fileURL)

        XCTAssertTrue(cache.load().isEmpty)
    }

    // MARK: - Repository

    func test_fetchingTrendingPodcasts_savesThemForTheNextLaunch() async throws {
        StationsURLProtocol.body = #"{"results":[{"collectionId":1,"collectionName":"Trending","feedUrl":"https://example.com/t"}]}"#
        let repository = makeRepository()

        _ = try await repository.fetchTrendingPodcasts()

        let saved = await repository.cachedTrendingPodcasts()
        XCTAssertEqual(saved.map(\.title), ["Trending"])
    }

    func test_failedOrEmptyFetch_keepsTheSavedStations() async {
        cache.save([makePodcast(title: "Saved")])
        let repository = makeRepository()

        _ = try? await repository.fetchTrendingPodcasts()
        StationsURLProtocol.status = 503
        _ = try? await repository.fetchTrendingPodcasts()

        XCTAssertEqual(cache.load().map(\.title), ["Saved"])
    }

    private func makeRepository() -> PodcastsRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StationsURLProtocol.self]
        let api = APIService(session: URLSession(configuration: configuration),
                             onAirBaseURL: URL(string: "https://api.example.com")!)
        return PodcastsRepository(api: api, store: CoreDataStack(inMemory: true), stationsCache: cache)
    }
}

/// Answers every request with `status` and `body`.
private final class StationsURLProtocol: URLProtocol {
    static var status = 200
    static var body = ""

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
