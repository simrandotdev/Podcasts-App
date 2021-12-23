import UIKit
import SwiftUI

class MainTabBarController : UITabBarController
{
    let playerDetailsView = PlayerDetailsView.initFromNib()
    var maximizeTopAnchorConstraint: NSLayoutConstraint!
    var minimizeTopAnchorConstraint: NSLayoutConstraint!
    
    override
    func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarController()
        setupViewController()
        setupPlayerDetailsView()
        playerDetailsView.isHidden = true
    }
    
    // MARK: Handlers
    @objc func minimizePlayerDetails() {
        maximizeTopAnchorConstraint.isActive = false
        minimizeTopAnchorConstraint.isActive = true
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.playerDetailsView.isHidden = false
            self.tabBar.isHidden = false
            self.playerDetailsView.maximizedStackView.alpha = 0.0
            self.playerDetailsView.minimizedStackView.alpha = 1.0
        }, completion: nil)
    }
    
    func maximizePlayerDetails(episode: EpisodeViewModel?, playListEpisodes: [EpisodeViewModel]?) {
        minimizeTopAnchorConstraint.isActive = false
        maximizeTopAnchorConstraint.constant = 0
        maximizeTopAnchorConstraint.isActive = true
        
        if let episode = episode {
            playerDetailsView.episodeViewModel = episode
            playerDetailsView.playListEpisodes = playListEpisodes
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.playerDetailsView.isHidden = false
            self.tabBar.isHidden = true
            self.playerDetailsView.maximizedStackView.alpha = 1.0
            self.playerDetailsView.minimizedStackView.alpha = 0.0
        }, completion: nil)
    }
    
    // MARK:- Setup methods
    fileprivate func setupTabBarNavigationController(title: String, image: UIImage, viewController: UIViewController) -> UINavigationController {
        viewController.navigationItem.title = title
        viewController.tabBarItem.title = title
        viewController.tabBarItem.image = image
        let navController = UINavigationController(rootViewController: viewController)
        return navController
    }
    
    fileprivate func setupTabBarController() {
        view.backgroundColor = Theme.Color.systemBackgroundColor
    }
    
    fileprivate func setupViewController() {
        let favoriteNavController = setupTabBarNavigationController(title: "Favorites",
                                                                    image: UIImage(systemName: "star.fill") ?? UIImage(),
                                                                    viewController: FavoritePodcastsViewController(collectionViewLayout: UICollectionViewFlowLayout()))
        
        let searchNavController = setupTabBarNavigationController(title: "Search",
                                                                  image: UIImage(systemName: "magnifyingglass") ?? UIImage(),
                                                                  viewController: PodcastsSearchViewController())
        
        let recentEpisodesNavController = setupTabBarNavigationController(title: "History",
                                                                          image: UIImage(systemName: "square.stack.fill") ?? UIImage(),
                                                                          viewController: RecentEpisodesViewController())
        
        let settingsViewNavController = setupTabBarNavigationController(title: "Settings",
                                                                        image: UIImage(systemName: "gear") ?? UIImage(),
                                                                        viewController: UIHostingController(rootView: SettingsView()))
        
        viewControllers = [
            searchNavController,
            favoriteNavController,
            recentEpisodesNavController,
//            settingsViewNavController
        ]
    }
    
    fileprivate func setupPlayerDetailsView() {
        view.insertSubview(playerDetailsView, belowSubview: tabBar)
        playerDetailsView.translatesAutoresizingMaskIntoConstraints = false
        playerDetailsView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playerDetailsView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        playerDetailsView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        maximizeTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height)
        maximizeTopAnchorConstraint.isActive = true
        minimizeTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: -64)
        
        let swipeDownGesture = UIPanGestureRecognizer(target: self, action: #selector(panPiece))
        playerDetailsView.addGestureRecognizer(swipeDownGesture)
    }
    
    @objc func panPiece(_ gestureRecognizer : UIPanGestureRecognizer) {
        guard gestureRecognizer.view != nil else {return}
        let piece = gestureRecognizer.view!
        let translation = gestureRecognizer.translation(in: piece.superview)
        
        if translation.y > 170 {
            minimizePlayerDetails()
        }
        
        if translation.y < -170 {
            maximizePlayerDetails(episode: nil, playListEpisodes: nil)
        }
    }
}
