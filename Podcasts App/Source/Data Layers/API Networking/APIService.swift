import Foundation
import FeedKit

final class APIService {
    static let shared = APIService()
    private let session: URLSession

    init(session: URLSession? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = session ?? URLSession(configuration: configuration)
    }

    func fetchPodcastsAsync(searchText: String) async throws -> [Podcast] {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: searchText),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "50")
        ]
        guard let url = components.url else { throw APIError.invalidRequest }
        let data = try await fetchData(from: url)
        let results = try JSONDecoder().decode(PodcastSearchResponse.self, from: data)
        // Some search results have no usable feed; de-duplicate by the persistence key.
        var feeds = Set<String>()
        return results.results.compactMap { result in
            guard let feed = result.feedUrl, !feed.isEmpty, feeds.insert(feed).inserted else { return nil }
            return Podcast(recordId: String(result.collectionId), title: result.collectionName,
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
        return rss.toEpisodes()
    }

    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidRequest }
        guard (200..<300).contains(response.statusCode) else { throw APIError.httpStatus(response.statusCode) }
        try Task.checkCancellation()
        return data
    }
}

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
