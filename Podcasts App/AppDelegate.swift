import UIKit

let primaryColor = UIColor(red: 0.15, green: 0.20, blue: 0.22, alpha: 1.0);
let primaryLightColor = UIColor(red: 0.31, green: 0.36, blue: 0.38, alpha: 1.0);
let primaryDarkColor = UIColor(red: 0.00, green: 0.04, blue: 0.07, alpha: 1.0);
let primaryDarkTextColor = UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0);
let primaryLightTextColor = UIColor.white

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.rootViewController = MainTabBarController()
        
        setupAppUI()
        
        return true
    }
    
    func setupAppUI() {
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = primaryColor
        UINavigationBar.appearance().tintColor = primaryLightColor
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: primaryLightTextColor]
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: primaryLightTextColor,
            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 24)
        ]
        
        UITabBar.appearance().tintColor = primaryDarkColor
        
        UISearchBar.appearance().tintColor = primaryLightTextColor
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: primaryLightTextColor]
    }
}
