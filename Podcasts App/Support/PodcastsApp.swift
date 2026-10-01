import SwiftUI
import Resolver

@main
struct PodcastsApp: App {
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
                .tint(.purple)
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
        }
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
