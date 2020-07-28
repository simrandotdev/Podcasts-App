import UIKit

class FavoritePodcastsViewController: UICollectionViewController {
    private let cellId = "favoritesCellId"
    var favoritePodcasts : [Podcast]? = [Podcast]()
    fileprivate let favoritePodcastRepository = PodcastsPersistantManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .systemBackground
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        favoritePodcasts = favoritePodcastRepository.fetchFavoritePodcasts()
        collectionView?.reloadData()
    }
    
    // MARK:- Setups
    fileprivate func setupCollectionView() {
        collectionView?.register(FavoritePodcastCell.self, forCellWithReuseIdentifier: cellId)
    }
    
}

// MARK: CollectionView
extension FavoritePodcastsViewController : UICollectionViewDelegateFlowLayout {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favoritePodcasts?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FavoritePodcastCell
        if let podcast = favoritePodcasts?[indexPath.row] {
            cell.setupCell(podcast: podcast)
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let favoritePodcast = favoritePodcasts?[indexPath.row] else { return }
        let episodeController = EpisodesViewController()
        episodeController.podcastViewModel = PodcastViewModel(podcast: favoritePodcast)
        navigationController?.pushViewController(episodeController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (collectionView.frame.width  - (3 * 8)) / 2
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 2, bottom: 16, right: 2)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
}
