import UIKit

class MainTabBarController : UITabBarController
{
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        setupTabBarController()
        
        let favoriteNavController =
            setupTabBarNavigationController(title: "Favorites", image: #imageLiteral(resourceName: "favorites"), viewController: FavoriteViewController())
        let searchNavController =
            setupTabBarNavigationController(title: "Search", image: #imageLiteral(resourceName: "search"), viewController: SearchViewController())
        let downloadNavController =
            setupTabBarNavigationController(title: "Downloads", image: #imageLiteral(resourceName: "downloads"), viewController: DownloadViewController())
        
        viewControllers =
        [
            favoriteNavController,
            searchNavController,
            downloadNavController
        ]
    }
    
    // MARK:- Setup methods
    fileprivate
    func setupTabBarNavigationController(title: String, image: UIImage, viewController: UIViewController) -> UINavigationController
    {
        viewController.navigationItem.title = title
        viewController.tabBarItem.title = title
        viewController.tabBarItem.image = image
        let navController = UINavigationController(rootViewController: viewController)
        return navController
    }
    
    fileprivate
    func setupTabBarController()
    {
        view.backgroundColor = .white
        tabBar.tintColor = .purple
        UINavigationBar.appearance().prefersLargeTitles = true
    }
}
