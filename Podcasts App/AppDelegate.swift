import UIKit


let primaryDarkColor = UIColor.systemGray6
let primaryLightColor = UIColor.systemBackground


let primaryDarkTextColor = UIColor.black
let primaryLightTextColor = UIColor.gray

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.rootViewController = MainTabBarController()
        
        setupAppUI()
        
        return true
    }
    
    func setupAppUI() {
        UINavigationBar.appearance().prefersLargeTitles = true
    }
}

extension UILabel {
    var defaultFont: UIFont? {
        get { return self.font }
        set { self.font = newValue }
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
