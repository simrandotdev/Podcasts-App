import Foundation
import FeedKit

final class APIService {
    static let shared = APIService()
    private let session: URLSession
    /// The On Air API (`OnAirAPI/` in the repository), which searches Podcast Index. Without it, podcasts come
    /// from the iTunes Search API. Both return the same response format.
    private let onAirBaseURL: URL?

    /// The iTunes search the Home list falls back to when the On Air API isn't configured.
    static let iTunesHomeSearchTerm = "podcasts"
    private static let resultLimit = "50"

    init(session: URLSession? = nil, onAirBaseURL: URL? = APIService.configuredOnAirBaseURL) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = session ?? URLSession(configuration: configuration)
        self.onAirBaseURL = onAirBaseURL
    }

    /// The `OnAirAPIBaseURL` value in Info.plist, set per build configuration by the `ONAIR_API_BASE_URL`
    /// build setting. Empty means the On Air API isn't used.
    static var configuredOnAirBaseURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "OnAirAPIBaseURL") as? String,
              !value.isEmpty else { return nil }
        return URL(string: value)
    }

    /// Podcasts whose title, author or owner matches `searchText`.
    func fetchPodcastsAsync(searchText: String) async throws -> [Podcast] {
        let url: URL?
        if let onAirBaseURL {
            url = Self.url(onAirBaseURL.appendingPathComponent("v1/search"),
                           query: ["term": searchText, "limit": Self.resultLimit])
        } else {
            url = Self.url(URL(string: "https://itunes.apple.com/search")!,
                           query: ["term": searchText, "media": "podcast", "entity": "podcast",
                                   "limit": Self.resultLimit])
        }
        return try await fetchPodcasts(from: url)
    }

    /// Podcasts for the Home list: trending podcasts from the On Air API, or an iTunes search for "podcasts".
    func fetchTrendingPodcastsAsync() async throws -> [Podcast] {
        guard let onAirBaseURL else { return try await fetchPodcastsAsync(searchText: Self.iTunesHomeSearchTerm) }
        return try await fetchPodcasts(from: Self.url(onAirBaseURL.appendingPathComponent("v1/podcasts/trending"),
                                                      query: ["limit": Self.resultLimit]))
    }

    private static func url(_ base: URL, query: KeyValuePairs<String, String>) -> URL? {
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components?.url
    }

    private func fetchPodcasts(from url: URL?) async throws -> [Podcast] {
        guard let url else { throw APIError.invalidRequest }
        let data = try await fetchData(from: url)
        let results = try JSONDecoder().decode(PodcastSearchResponse.self, from: data)
        // Some search results have no usable feed; de-duplicate by the persistence key.
        var feeds = Set<String>()
        return results.results.compactMap { result in
            guard let feed = result.feedUrl, !feed.isEmpty, feeds.insert(feed).inserted else { return nil }
            // The On Air API identifies podcasts by their Podcast Index ID and adds the iTunes ID when it's known.
            // Prefer the iTunes ID, so podcasts keep the record ID they had when the app searched iTunes.
            return Podcast(recordId: String(result.itunesId ?? result.collectionId), title: result.collectionName,
                           author: result.artistName ?? "", image: result.artworkUrl600 ?? result.artworkUrl100 ?? "",
                           totalEpisodes: result.trackCount ?? 0, rssFeedUrl: feed)
        }
    }

    func fetchEpisodesAsync(forPodcast rssUrl: String) async throws -> [Episode] {
        guard let url = URL(string: rssUrl) else { throw APIError.invalidRequest }
        let data = try await fetchData(from: url)
        try Task.checkCancellation()
        // Parsing in the async service keeps it off the main actor and guarantees a result
        // for unsupported feeds instead of leaving a checked continuation suspended.
        let feed = try FeedParser(data: data).parse().get()
        guard let rss = feed.rssFeed else { throw APIError.failedToParseRss }
        return rss.toEpisodes(podcastFeedUrl: rssUrl)
    }

    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidRequest }
        guard (200..<300).contains(response.statusCode) else { throw APIError.httpStatus(response.statusCode) }
        try Task.checkCancellation()
        return data
    }
}

/// The iTunes Search API's response format, which the On Air API also returns.
private struct PodcastSearchResponse: Decodable {
    let results: [Result]

    struct Result: Decodable {
        let collectionId: Int
        let collectionName: String
        let artistName: String?
        let artworkUrl600: String?
        let artworkUrl100: String?
        let trackCount: Int?
        let feedUrl: String?
        /// Only in On Air API results, when Podcast Index knows the podcast's iTunes ID.
        let itunesId: Int?
    }
}

enum APIError: LocalizedError {
    case failedToParseRss
    case failedToParseJSON
    case invalidRequest
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .failedToParseRss: return "This address does not contain a supported podcast RSS feed."
        case .failedToParseJSON: return "The podcast service returned an unreadable response."
        case .invalidRequest: return "The podcast address or server response is invalid."
        case .httpStatus(let code): return "The server returned HTTP \(code). Please try again."
        }
    }
}
