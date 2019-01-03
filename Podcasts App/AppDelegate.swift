import UIKit

let primaryColor = UIColor.white //UIColor(red: 0.15, green: 0.20, blue: 0.22, alpha: 1.0);
let primaryLightColor = UIColor.white //UIColor(red: 0.31, green: 0.36, blue: 0.38, alpha: 1.0);
let primaryDarkColor = UIColor.white //UIColor(red: 0.00, green: 0.04, blue: 0.07, alpha: 1.0);
let primaryDarkTextColor = UIColor.black //UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0);
let primaryLightTextColor = UIColor.black //UIColor.white


func randomMaterialColor() -> UIColor {
    
    let colors = [
        UIColor.rgb(red: 244, green: 67, blue: 54),
        UIColor.rgb(red: 233, green: 30, blue: 99),
        UIColor.rgb(red: 156, green: 39, blue: 176),
        UIColor.rgb(red: 103, green: 58, blue: 183),
        UIColor.rgb(red: 63, green: 81, blue: 181),
        UIColor.rgb(red: 33, green: 150, blue: 243),
        UIColor.rgb(red: 3, green: 169, blue: 244),
        UIColor.rgb(red: 0, green: 188, blue: 212),
        UIColor.rgb(red: 0, green: 150, blue: 136),
        UIColor.rgb(red: 76, green: 175, blue: 80),
        UIColor.rgb(red: 139, green: 195, blue: 74),
        UIColor.rgb(red: 205, green: 220, blue: 57),
        UIColor.rgb(red: 255, green: 235, blue: 59),
        UIColor.rgb(red: 255, green: 193, blue: 7),
        UIColor.rgb(red: 255, green: 152, blue: 0),
        ]
    
    let randomIndex = Int(arc4random_uniform(UInt32(colors.count)))
    
    return colors[randomIndex]
}


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
        UITabBar.appearance().tintColor = .black
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
