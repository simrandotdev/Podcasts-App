import UIKit
import Resolver

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.rootViewController = MainTabBarController()
        setupAppUI()

        return true
    }
    
    private func setupAppUI() {
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().isOpaque = true
        UINavigationBar.appearance().isTranslucent = true
        
        UITabBar.appearance().tintColor = Theme.Color.primaryColor
        UINavigationBar.appearance().tintColor = Theme.Color.primaryColor
    }
}


struct Theme {
    
    struct Color {
        static let primaryColor             = UIColor.systemPurple
        static let labelColor               = UIColor.label
        static let secondaryColor           = UIColor.secondaryLabel
        static let tertiaryColor            = UIColor.tertiaryLabel
        static let systemBackgroundColor    = UIColor.systemBackground
    }
}


extension Resolver: ResolverRegistering {
    
    public static func registerAllServices() {
        register { URLSession(configuration: .default) }
        register { LocalStorageManager() }.scope(.application)
        register { APIService.shared }
        register { PodcastsListViewModel() }
        register { PodcastDetailViewModel() }
        register { FavoritePodcastsViewModel() }
        register { RecentEpisodesListViewModel() }
        register { PodcastsPersistantManager() }
    }
}
