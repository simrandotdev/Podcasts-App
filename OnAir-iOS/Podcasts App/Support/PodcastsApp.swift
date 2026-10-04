import SwiftUI
import Resolver

@main
struct PodcastsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    // App-wide view models, shared by every screen so playback and downloads survive navigation.
    @State private var player = PlayerViewModel()
    @State private var downloads = DownloadsViewModel()
    @State private var newEpisodes = NewEpisodesViewModel()
    @State private var isShowingSplash = true

    init() {
        // AsyncImage loads through URLSession.shared; a larger cache keeps artwork from
        // re-downloading while scrolling (previously handled by SDWebImage).
        URLCache.shared = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environment(player)
                .environment(downloads)
                .environment(newEpisodes)
                .font(.system(.body, design: .rounded))
                .overlay {
                    if isShowingSplash {
                        SplashView { isShowingSplash = false }
                    }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                player.saveProgress()
            }
            switch phase {
            case .active: Task { await newEpisodes.refreshIfStale() }
            case .background: newEpisodes.scheduleBackgroundRefresh()
            default: break
            }
        }
        // iOS wakes the app periodically to check presets for new episodes.
        .backgroundTask(.appRefresh(NewEpisodesManager.refreshTaskIdentifier)) {
            await NewEpisodesManager.shared.refreshInBackground()
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

/// Data-layer and business-layer registrations. ViewModels resolve their managers from here; the
/// app-wide `PlaybackManager`, `DownloadManager` and `NewEpisodesManager` are main-actor singletons
/// (`.shared`) that ViewModels take as initializer defaults instead.
extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        // Services and persistence
        register { APIService.shared }
        register { CoreDataStack.shared }
        // Repositories
        register(PodcastsRepositoryProtocol.self) { PodcastsRepository(api: resolve(), store: resolve()) }
            .scope(.application)
        register(EpisodesRepositoryProtocol.self) { EpisodesRepository(api: resolve(), store: resolve()) }
            .scope(.application)
        // Managers. Application scope, so everyone shares their change notifications.
        register(PodcastsManaging.self) { PodcastsManager(repository: resolve()) }
            .scope(.application)
        register(EpisodesManaging.self) { EpisodesManager(repository: resolve()) }
            .scope(.application)
    }
}
