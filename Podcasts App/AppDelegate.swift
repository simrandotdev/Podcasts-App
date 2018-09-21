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
        UINavigationBar.appearance().barTintColor = primaryColor
        UINavigationBar.appearance().tintColor = primaryLightColor
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: primaryLightTextColor]
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: primaryLightTextColor,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
        ]
        
        UITabBar.appearance().tintColor = primaryDarkColor
        UITabBar.appearance().backgroundColor = primaryLightColor
        
        UISearchBar.appearance().tintColor = primaryLightTextColor
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = convertToNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: primaryLightTextColor])
        
        UILabel.appearance().textColor = primaryLightTextColor
        
        UITableView.appearance().backgroundColor = primaryLightColor
        UITableViewCell.appearance().backgroundColor = primaryLightColor
        
        UICollectionViewCell.appearance().backgroundColor = primaryLightColor
        UICollectionView.appearance().backgroundColor = primaryLightColor
        
        UIStackView.appearance(whenContainedInInstancesOf: [PlayerDetailsView.self]).backgroundColor = primaryLightColor
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
