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
        
        syncLocalFavoritesWithCloudKit()
        
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


extension AppDelegate {
    func syncLocalFavoritesWithCloudKit() {
        let localPersistance = PodcastsPersistantManager()
        let bkManager = BaadalManager(identifier: "iCloud.app.simran.PodcastsApp")
        let favoritePodcasts = localPersistance.fetchFavoritePodcasts()
        
        if favoritePodcasts.count > 0 {
            for podcast in favoritePodcasts {
                Task {
                    let favoritePodcastRecord = CKRecord(recordType: "FavoritePodcasts") // TODO: Extract into some place common
                    favoritePodcastRecord.setValue(podcast.author, forKey: "author")
                    favoritePodcastRecord.setValue(podcast.title, forKey: "title")
                    favoritePodcastRecord.setValue(podcast.image, forKey: "image")
                    favoritePodcastRecord.setValue(podcast.totalEpisodes, forKey: "totalEpisodes")
                    favoritePodcastRecord.setValue(podcast.rssFeedUrl, forKey: "rssFeedUrl")
                    
                    do {
                        _ = try await bkManager.save(record: favoritePodcastRecord)
                    } catch {
                        print("❌ Error syncing favorite podcasts with error: \(error)")
                    }
                }
            }
        }
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
    }
}
