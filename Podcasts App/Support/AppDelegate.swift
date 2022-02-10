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
        UINavigationBar.appearance().prefersLargeTitles         = true
        UINavigationBar.appearance().isOpaque                   = true
        UINavigationBar.appearance().isTranslucent              = true
        UINavigationBar.appearance().tintColor                  = Theme.Color.primaryColor
        UINavigationBar.appearance().largeTitleTextAttributes   = [
            .font: Theme.Font.largeTitle
        ]
        UINavigationBar.appearance().titleTextAttributes        = [
            .font: Theme.Font.title3
        ]
        
        UITabBar.appearance().tintColor = Theme.Color.primaryColor
        UITabBarItem.appearance().setTitleTextAttributes([
            .font: Theme.Font.caption1
        ], for: .normal)
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
    
    struct Font {
        private static var fontName = "Arial Rounded MT Bold"
        
        static var largeTitle: UIFont {
            let font = UIFont.systemFont(ofSize: 34)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.largeTitle)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 34))
        }
        
        static var title1: UIFont {
            let font = UIFont.systemFont(ofSize: 28)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.title1)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 28))
        }
        
        
        static var title2: UIFont {
            let font = UIFont.systemFont(ofSize: 22)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.title2)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 22))
        }
        
        static var title3: UIFont {
            let font = UIFont.systemFont(ofSize: 20)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.title3)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 20))
        }
        
        
        static var body: UIFont {
            let font = UIFont.systemFont(ofSize: 17)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.body)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 17))
        }
        
        static var callout: UIFont {
            let font = UIFont.systemFont(ofSize: 16)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.callout)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 16))
        }
        
        static var subHead: UIFont {
            let font = UIFont.systemFont(ofSize: 15)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.subheadline)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 15))
        }
        
        static var footnote: UIFont {
            let font = UIFont.systemFont(ofSize: 13)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.footnote)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 13))
        }
        
        static var caption1: UIFont {
            let font = UIFont.systemFont(ofSize: 12)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.caption1)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 12))
        }
        
        static var caption2: UIFont {
            let font = UIFont.systemFont(ofSize: 11)
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.caption2)
            let description = font.fontDescriptor.withDesign(.rounded)!
            return fontMetrics.scaledFont(for: UIFont(descriptor: description, size: 11))
        }
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
