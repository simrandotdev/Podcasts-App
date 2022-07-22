import UIKit
import SwiftUI

class MainTabBarController : UITabBarController {
    
    let playerDetailsView = PlayerDetailsView.initFromNib()
    var maximizeTopAnchorConstraint: NSLayoutConstraint!
    var minimizeTopAnchorConstraint: NSLayoutConstraint!
    var minimizeBottomAnchorConstraint: NSLayoutConstraint!
    var maximizeBottomAnchorConstraint: NSLayoutConstraint!
    
    var iPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupTabBarController()
        setupPlayerDetailsView()
        playerDetailsView.isHidden = true
    }
    
    
    // MARK:- Setup methods

    
    fileprivate func setupTabBarNavigationController(title: String, image: UIImage, viewController: UIViewController) -> UINavigationController {
        
        viewController.navigationItem.title = title
        viewController.tabBarItem.title = title
        viewController.tabBarItem.image = image
        let navController = UINavigationController(rootViewController: viewController)
        return navController
    }
    
    
    private lazy var tabHostController = UIHostingController(rootView: AppTabView(maximizePlayerView: maximizePlayerDetails))
    fileprivate func setupTabBarController() {
        
        view.backgroundColor = Theme.Color.systemBackgroundColor
        self.tabBar.isHidden = true
        
        
        tabHostController.view.frame = view.bounds
        view.insertSubview(tabHostController.view, aboveSubview: view)
    }
    
    
    fileprivate func setupPlayerDetailsView() {
        
        view.insertSubview(playerDetailsView, aboveSubview: tabHostController.view)
        playerDetailsView.translatesAutoresizingMaskIntoConstraints = false
        playerDetailsView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playerDetailsView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        
        maximizeBottomAnchorConstraint = playerDetailsView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        maximizeBottomAnchorConstraint.isActive = true
        
        minimizeBottomAnchorConstraint = playerDetailsView.bottomAnchor.constraint(equalTo: iPad ? self.view.bottomAnchor : self.tabBar.topAnchor)
        
        maximizeTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height )
        maximizeTopAnchorConstraint.isActive = true
        
        minimizeTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: iPad ? -12 : -64)
                
        let swipeDownGesture = UIPanGestureRecognizer(target: self, action: #selector(panPiece))
        playerDetailsView.addGestureRecognizer(swipeDownGesture)
        playerDetailsView.minimizePlayerDetails = minimizePlayerDetails
        playerDetailsView.maximizePlayer = maximizePlayerDetails
    }
    
    
    // MARK: Handlers
    
    
    @objc func minimizePlayerDetails() {
        
        maximizeTopAnchorConstraint.isActive = false
        maximizeBottomAnchorConstraint.isActive = false
        
        minimizeTopAnchorConstraint.isActive = true
        minimizeBottomAnchorConstraint.isActive = true
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.playerDetailsView.isHidden = false
            self.playerDetailsView.maximizedStackView.alpha = 0.0
            self.playerDetailsView.minimizedStackView.alpha = 1.0
        }, completion: nil)
    }
    
    
    func maximizePlayerDetails(episode: EpisodeViewModel?, playListEpisodes: [EpisodeViewModel]?) {
        
        minimizeTopAnchorConstraint.isActive = false
        minimizeBottomAnchorConstraint.isActive = false
        maximizeTopAnchorConstraint.constant = 0
        
        maximizeTopAnchorConstraint.isActive = true
        maximizeBottomAnchorConstraint.isActive = true
        
        if let episode = episode {
            playerDetailsView.episodeViewModel = episode
            playerDetailsView.playListEpisodes = playListEpisodes
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: { [weak self] in
            
            guard let self = self else { return }
            self.view.layoutIfNeeded()
            self.playerDetailsView.isHidden = false
            self.playerDetailsView.maximizedStackView.alpha = 1.0
            self.playerDetailsView.minimizedStackView.alpha = 0.0
        }, completion: nil)
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

    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        tabHostController.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        tabHostController.view.frame = CGRect(x: 0, y: 0, width: view.bounds.height, height: view.bounds.width)

    }
}
