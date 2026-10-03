import Foundation
import Combine

/// Backs `SettingsView`: listening activity, the artwork cache and the app version. Download and
/// new-episode settings come from `DownloadsViewModel` and `NewEpisodesViewModel`.
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var cacheBytes: Int64 = 0

    private let playback: PlaybackManager
    private let urlCache: URLCache
    private var subscription: AnyCancellable?

    /// - Parameter playback: Defaults to the app's shared player.
    init(playback: PlaybackManager? = nil, urlCache: URLCache = .shared) {
        self.playback = playback ?? .shared
        self.urlCache = urlCache
        // The player publishes its position every second while playing, so the heatmap stays current.
        subscription = self.playback.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        refreshCacheSize()
    }

    /// The last year of listening.
    var heatmap: ListeningHeatmap { ListeningHeatmap(stats: playback.listeningStats) }

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
