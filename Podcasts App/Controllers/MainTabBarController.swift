import UIKit

class MainTabBarController : UITabBarController
{
    let playerDetailsView = PlayerDetailsView.initFromNib()
    var maximizeTopAnchorConstraint: NSLayoutConstraint!
    var minimizeTopAnchorConstraint: NSLayoutConstraint!
    
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        setupTabBarController()
        setupViewController()
        setupPlayerDetailsView()

        perform(#selector(maximizePlayerDetails), with: nil, afterDelay: 1)
    }
    
    // MARK: Handlers
    @objc func minimizePlayerDetails()
    {
        maximizeTopAnchorConstraint.isActive = false
        minimizeTopAnchorConstraint.isActive = true
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func maximizePlayerDetails()
    {
        minimizeTopAnchorConstraint.isActive = false
        maximizeTopAnchorConstraint.constant = 0
        maximizeTopAnchorConstraint.isActive = true
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
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
    }
    
    fileprivate
    func setupViewController()
    {
        let favoriteNavController =
            setupTabBarNavigationController(title: "Favorites", image: #imageLiteral(resourceName: "favorites"), viewController: FavoriteViewController())
        let searchNavController =
            setupTabBarNavigationController(title: "Search", image: #imageLiteral(resourceName: "search"), viewController: SearchViewController())
        let downloadNavController =
            setupTabBarNavigationController(title: "Downloads", image: #imageLiteral(resourceName: "downloads"), viewController: DownloadViewController())
        
        viewControllers =
            [
                searchNavController,
                favoriteNavController,
                downloadNavController
        ]
    }
    
    fileprivate
    func setupPlayerDetailsView()
    {
        
        view.insertSubview(playerDetailsView, belowSubview: tabBar)
        playerDetailsView.translatesAutoresizingMaskIntoConstraints = false
        
        maximizeTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height)
        maximizeTopAnchorConstraint.isActive = true
        
        minimizeTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: -64)
        
        playerDetailsView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playerDetailsView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        playerDetailsView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
    }
}
