import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        
        let rootViewController = MainTabBarController()
        let navigationController = UINavigationController(rootViewController: rootViewController)

        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.rootViewController = navigationController
        
        return true
    }
}

