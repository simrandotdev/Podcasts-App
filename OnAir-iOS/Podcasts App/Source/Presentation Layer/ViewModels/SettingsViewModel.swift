import Foundation
import Observation

/// Backs `SettingsView`: listening activity, the artwork cache and the app version. Download and
/// new-episode settings come from `DownloadsViewModel` and `NewEpisodesViewModel`.
@MainActor
@Observable
final class SettingsViewModel {
    private(set) var cacheBytes: Int64 = 0

    private let playback: PlaybackManager
    private let urlCache: URLCache

    /// - Parameter playback: Defaults to the app's shared player.
    init(playback: PlaybackManager? = nil, urlCache: URLCache = .shared) {
        self.playback = playback ?? .shared
        self.urlCache = urlCache
        refreshCacheSize()
    }

    /// The last year of listening.
    var heatmap: ListeningHeatmap {
        // Listening time lives in UserDefaults, which isn't observable. Reading the revision makes views
        // update each time the player records more, about once a second while playing.
        _ = playback.listeningStatsRevision
        return ListeningHeatmap(stats: playback.listeningStats)
    }

    var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }

    func refreshCacheSize() {
        cacheBytes = Int64(urlCache.currentDiskUsage)
    }

    /// Removes saved artwork and other cached responses, not downloaded episodes.
    func clearCache() {
        urlCache.removeAllCachedResponses()
        refreshCacheSize()
    }
}
