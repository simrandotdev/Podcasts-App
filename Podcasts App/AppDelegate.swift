import UIKit
import Resolver

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UITabBar.appearance().tintColor = .systemPurple
        UINavigationBar.appearance().tintColor = .systemPurple
        
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.rootViewController = MainTabBarController()
        setupAppUI()
        return true
    }
    
    private func setupAppUI() {
        UINavigationBar.appearance().prefersLargeTitles = true
    }
}


extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { URLSession(configuration: .default) }
        register { APIService.shared }
        register { PodcastsListViewModel() }
        register { EpisodesListViewModel() }
        register { RecentEpisodesListViewModel() }
        register { PodcastsPersistantManager() }
        
    }
}
