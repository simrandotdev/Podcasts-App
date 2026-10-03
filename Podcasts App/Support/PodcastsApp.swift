import SwiftUI
import Resolver

@main
struct PodcastsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var player = PlaybackController()
    @State private var isShowingSplash = true

    init() {
        // AsyncImage loads through URLSession.shared; a larger cache keeps artwork from
        // re-downloading while scrolling (previously handled by SDWebImage).
        URLCache.shared = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(player)
                .environmentObject(DownloadManager.shared)
                .environmentObject(NewEpisodeTracker.shared)
                .font(.system(.body, design: .rounded))
                .overlay {
                    if isShowingSplash {
                        SplashView { isShowingSplash = false }
                    }
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                player.saveProgress()
            }
            switch phase {
            case .active: Task { await NewEpisodeTracker.shared.refreshIfStale() }
            case .background: NewEpisodeTracker.shared.scheduleBackgroundRefresh()
            default: break
            }
        }
        // iOS wakes the app periodically to check presets for new episodes.
        .backgroundTask(.appRefresh(NewEpisodeTracker.refreshTaskIdentifier)) {
            await NewEpisodeTracker.shared.refreshInBackground()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// iOS relaunches the app to deliver finished background downloads. Reconnect to the session
    /// and hold the completion handler until the session has delivered every event.
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        guard identifier == DownloadManager.sessionIdentifier else {
            completionHandler()
            return
        }
        DownloadManager.backgroundEventsCompletionHandler = completionHandler
        _ = DownloadManager.shared
    }
}

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { URLSession(configuration: .default) }
        register { APIService.shared }
        register { PodcastsInteractor() }.implements(PodcastsInteractable.self)
        register { EpisodesInteractor() }.implements(EpisodesInteractable.self)
        register { PodcastsRepository() }.implements(PodcastsRepositoryProtocol.self)
        register { EpisodesRepository() }.implements(EpisodesRepositoryProtocol.self)
        register { PersistanceManager.shared }
    }
}
