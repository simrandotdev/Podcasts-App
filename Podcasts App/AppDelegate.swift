import UIKit


let primaryDarkColor = UIColor.black
let primaryLightColor = UIColor.white


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
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = primaryLightColor
        UINavigationBar.appearance().tintColor = primaryDarkTextColor
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: primaryDarkTextColor]
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: primaryDarkTextColor,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
        ]
        
        UITabBar.appearance().tintColor = primaryDarkColor
        UITabBar.appearance().backgroundColor = primaryLightColor
        
        UISearchBar.appearance().tintColor = primaryDarkTextColor
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = convertToNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: primaryDarkTextColor])
        
        UILabel.appearance().textColor = primaryDarkTextColor
        
        UITableView.appearance().backgroundColor = primaryLightColor
        UITableViewCell.appearance().backgroundColor = primaryLightColor
        
        UICollectionViewCell.appearance().backgroundColor = primaryLightColor
        UICollectionView.appearance().backgroundColor = primaryLightColor
        
        UIStackView.appearance(whenContainedInInstancesOf: [PlayerDetailsView.self]).backgroundColor = primaryLightColor
        UITabBar.appearance().tintColor = primaryDarkTextColor
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
