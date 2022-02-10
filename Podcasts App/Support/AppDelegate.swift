import UIKit
import Resolver
import BaadalKit
import CloudKit

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
        UINavigationBar.appearance().tintColor = Theme.Color.primaryColor
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(name: "Arial Rounded MT Bold", size: 36) ?? UIFont.systemFont(ofSize: 36),
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont(name: "Arial Rounded MT Bold", size: 20) ?? UIFont.systemFont(ofSize: 20)
        ]
        
        UITabBar.appearance().tintColor = Theme.Color.primaryColor
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
        register { PodcastsSearchViewModel() }
        register { PodcastDetailViewModel() }
        register { RecentEpisodesListViewModel() }
        register { PodcastsPersistantManager() }
        register { BaadalManager(identifier: Constants.BKConstants.container) }
        register { FavoritePodcastsService() }
        register { FavoritePodcastsViewModel() }
    }
}
