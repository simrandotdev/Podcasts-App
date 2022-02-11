import UIKit
import Resolver
import Combine

class FavoritePodcastsViewController: UICollectionViewController {
    
    private var numberOfSpaces: CGFloat = 3
    private let cellId = "favoritesCellId"
    private var cancellable = Set<AnyCancellable>()
    
    @Injected var favoritePodcastsViewModel: FavoritePodcastsViewModel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = Theme.Color.systemBackgroundColor
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        favoritePodcastsViewModel.$favoritePodcasts
            .receive(on: DispatchQueue.main)
            .sink { [collectionView] _ in
                collectionView?.reloadData()
            }.store(in: &cancellable)
        
        Task {
            try await favoritePodcastsViewModel.fetchFavoritePodcasts()
        }
        
        let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
        timer.sink { _ in
            Task {
                try await self.favoritePodcastsViewModel.fetchFavoritePodcasts()
            }
        }.store(in: &cancellable)
    }
    
    // MARK:- Setups
    fileprivate func setupCollectionView() {
        let favoritePodcastCellNib = UINib(nibName: "\(FavoritePodcastCell.self)", bundle: nil)
        collectionView.register(favoritePodcastCellNib, forCellWithReuseIdentifier: cellId)
    }
    
}

// MARK: CollectionView
extension FavoritePodcastsViewController : UICollectionViewDelegateFlowLayout {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favoritePodcastsViewModel.favoritePodcasts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FavoritePodcastCell
        let podcast = favoritePodcastsViewModel.favoritePodcasts[indexPath.row]
        cell.setupCell(podcast: podcast)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let favoritePodcast = favoritePodcastsViewModel.favoritePodcasts[indexPath.row]
        let episodeController = PodcastDetailsViewController()
        episodeController.podcastViewModel = favoritePodcast
        navigationController?.pushViewController(episodeController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        
        let size = (collectionView.frame.width  - (numberOfSpaces * 8)) / (numberOfSpaces - 1)
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 8, bottom: 8 , right: 4)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
    
    private func layoutTrait(traitCollection:UITraitCollection) {
        if traitCollection.horizontalSizeClass == .regular {
            numberOfSpaces = 4
        } else {
            numberOfSpaces = 3
        }
    }
        
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layoutTrait(traitCollection: traitCollection)
    }
}
