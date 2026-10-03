import XCTest
@testable import Podcasts_Bin

final class APIServiceTests: XCTestCase {
    private var session: URLSession!
    private var api: APIService!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PodcastURLProtocol.self]
        session = URLSession(configuration: configuration)
        // Without an On Air API address, searches fall back to iTunes.
        api = APIService(session: session, onAirBaseURL: nil)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        PodcastURLProtocol.respond = nil
        super.tearDown()
    }

    func test_searchWithoutOnAirAPI_queriesITunesAndMapsUniqueUsableFeeds() async throws {
        PodcastURLProtocol.respond = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            XCTAssertEqual(components.queryItems?.first(where: { $0.name == "term" })?.value, "news & science")
            XCTAssertEqual(components.queryItems?.first(where: { $0.name == "media" })?.value, "podcast")
            return (200, Data("""
            {"results":[
              {"collectionId":1,"collectionName":"Science","artistName":"Author","trackCount":12,
               "artworkUrl600":"https://example.com/art.jpg","feedUrl":"https://example.com/feed"},
              {"collectionId":2,"collectionName":"Duplicate","feedUrl":"https://example.com/feed"},
              {"collectionId":3,"collectionName":"Missing feed"}
            ]}
            """.utf8))
        }
        let result = try await api.fetchPodcastsAsync(searchText: "news & science")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.recordId, "1")
        XCTAssertEqual(result.first?.title, "Science")
        XCTAssertEqual(result.first?.totalEpisodes, 12)
        XCTAssertEqual(result.first?.image, "https://example.com/art.jpg")
    }

    func test_searchWithOnAirAPI_queriesV1SearchAndPrefersITunesIDs() async throws {
        let api = APIService(session: session, onAirBaseURL: URL(string: "https://api.example.com")!)
        PodcastURLProtocol.respond = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            XCTAssertEqual(components.host, "api.example.com")
            XCTAssertEqual(components.path, "/v1/search")
            XCTAssertEqual(components.queryItems?.first(where: { $0.name == "term" })?.value, "news & science")
            XCTAssertEqual(components.queryItems?.first(where: { $0.name == "limit" })?.value, "50")
            return (200, Data("""
            {"resultCount":2,"results":[
              {"collectionId":920666,"collectionName":"Known to iTunes","feedUrl":"https://example.com/a",
               "itunesId":1219454367},
              {"collectionId":42,"collectionName":"Podcast Index only","feedUrl":"https://example.com/b",
               "itunesId":null}
            ]}
            """.utf8))
        }
        let result = try await api.fetchPodcastsAsync(searchText: "news & science")
        XCTAssertEqual(result.map(\.recordId), ["1219454367", "42"])
        XCTAssertEqual(result.map(\.rssFeedUrl), ["https://example.com/a", "https://example.com/b"])
    }

    func test_trendingWithOnAirAPI_requestsTrendingPodcasts() async throws {
        let api = APIService(session: session, onAirBaseURL: URL(string: "http://127.0.0.1:8000")!)
        PodcastURLProtocol.respond = { request in
            XCTAssertEqual(request.url?.absoluteString, "http://127.0.0.1:8000/v1/podcasts/trending?limit=50")
            return (200, Data(#"{"results":[{"collectionId":1,"collectionName":"Trending","feedUrl":"https://example.com/t"}]}"#.utf8))
        }
        let result = try await api.fetchTrendingPodcastsAsync()
        XCTAssertEqual(result.first?.title, "Trending")
    }

    func test_trendingWithoutOnAirAPI_searchesITunesForPodcasts() async throws {
        PodcastURLProtocol.respond = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            XCTAssertEqual(components.host, "itunes.apple.com")
            XCTAssertEqual(components.queryItems?.first(where: { $0.name == "term" })?.value,
                           APIService.iTunesHomeSearchTerm)
            return (200, Data(#"{"results":[]}"#.utf8))
        }
        let result = try await api.fetchTrendingPodcastsAsync()
        XCTAssertTrue(result.isEmpty)
    }

    func test_httpFailure_isReportedBeforeDecoding() async {
        PodcastURLProtocol.respond = { _ in (503, Data("Service unavailable".utf8)) }
        do {
            _ = try await api.fetchPodcastsAsync(searchText: "science")
            XCTFail("Expected an HTTP error")
        } catch APIError.httpStatus(let status) {
            XCTAssertEqual(status, 503)
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func test_rssFeed_preservesEpisodeAndChannelArtwork() async throws {
        PodcastURLProtocol.respond = { _ in
            (200, Data("""
            <?xml version="1.0" encoding="UTF-8"?>
            <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
              <channel><title>Show</title><link>https://example.com</link><description>A show</description>
                <itunes:image href="https://example.com/art.jpg"/>
                <item><title>Episode</title><description>Description</description>
                  <itunes:author>Author</itunes:author>
                  <enclosure url="https://example.com/audio.mp3" type="audio/mpeg" length="123"/>
                </item>
              </channel>
            </rss>
            """.utf8))
        }
        let episodes = try await api.fetchEpisodesAsync(forPodcast: "https://example.com/feed")
        XCTAssertEqual(episodes.count, 1)
        XCTAssertEqual(episodes.first?.streamUrl, "https://example.com/audio.mp3")
        XCTAssertEqual(episodes.first?.imageUrl, "https://example.com/art.jpg")
        XCTAssertEqual(episodes.first?.author, "Author")
        XCTAssertEqual(episodes.first?.podcastFeedUrl, "https://example.com/feed")
    }

    func test_nonRSSFeed_returnsFailureInsteadOfHanging() async {
        PodcastURLProtocol.respond = { _ in
            (200, Data("""
            {"version":"https://jsonfeed.org/version/1","title":"Not RSS","items":[]}
            """.utf8))
        }
        do {
            _ = try await api.fetchEpisodesAsync(forPodcast: "https://example.com/feed")
            XCTFail("Expected unsupported feed error")
        } catch APIError.failedToParseRss {
            // Every successful parser result must either return episodes or throw.
        } catch { XCTFail("Unexpected error: \(error)") }
    }
}

private final class PodcastURLProtocol: URLProtocol {
    static var respond: ((URLRequest) throws -> (Int, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, data) = try Self.respond!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}
