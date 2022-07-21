import UIKit
import SwiftUI

class MainTabBarController : UITabBarController {
    
    let playerDetailsView = PlayerDetailsView.initFromNib()
    var maximizeTopAnchorConstraint: NSLayoutConstraint!
    var minimizeTopAnchorConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        
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
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: { [weak self] in
            
            guard let self = self else { return }
            
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

        let searchPodcastScreen = PodcastsScreen(maximizePlayerView: maximizePlayerDetails)
        let searchNavController = setupTabBarNavigationController(title: "Search",
                                                                  image: UIImage(systemName: "magnifyingglass") ?? UIImage(),
                                                                  viewController: UIHostingController(rootView: searchPodcastScreen))
        let favoritesScreen = UIHostingController(rootView: FavoritesScreen(maximizePlayerView: maximizePlayerDetails))
        let favoritesViewNavController = setupTabBarNavigationController(title: "Favorites",
                                                                        image: UIImage(systemName: "heart.fill") ?? UIImage(),
                                                                        viewController: favoritesScreen)
        let recentlyPlayedEpisodesScreen = UIHostingController(rootView: RecentlyPlayedEpisodesScreen(maximizePlayerView: maximizePlayerDetails))
        let recentlyPlayedEpisodesNavController = setupTabBarNavigationController(title: "Recently Played",
                                                                        image: UIImage(systemName: "music.mic") ?? UIImage(),
                                                                        viewController: recentlyPlayedEpisodesScreen)
        
        let settingsScreen = UIHostingController(rootView: SettingsView())
        let settingsViewNavController = setupTabBarNavigationController(title: "Settings",
                                                                        image: UIImage(systemName: "gear") ?? UIImage(),
                                                                        viewController: settingsScreen)

        viewControllers = [
            searchNavController,
            favoritesViewNavController,
            recentlyPlayedEpisodesNavController
        ]

        #if DEBUG
        viewControllers?.append(settingsViewNavController)
        #endif
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
        playerDetailsView.minimizePlayerDetails = minimizePlayerDetails
        playerDetailsView.maximizePlayer = maximizePlayerDetails
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
