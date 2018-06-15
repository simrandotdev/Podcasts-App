import UIKit

class FavoriteViewController: UICollectionViewController
{
    private let cellId = "favoritesCellId"
    var favoritePodcasts : [Podcast]? = [Podcast]()
    fileprivate let favoritePodcastRepository = FavoritePodcastRepository()
    
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    override
    func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        favoritePodcasts = favoritePodcastRepository.fetchFavoritePodcasts()
        collectionView?.reloadData()
    }
    
    // MARK:- Setups
    fileprivate
    func setupCollectionView()
    {
        collectionView?.backgroundColor = .white
        collectionView?.register(FavoritePodcastCell.self, forCellWithReuseIdentifier: cellId)
    }
}

// MARK: CollectionView
extension FavoriteViewController : UICollectionViewDelegateFlowLayout
{
    override
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return favoritePodcasts?.count ?? 0
    }
    
    override
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FavoritePodcastCell
        if let podcast = favoritePodcasts?[indexPath.row] {
            cell.setupCell(podcast: podcast)
        }
        return cell
    }
    
    override
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let favoritePodcast = favoritePodcasts?[indexPath.row]
        let episodeController = EpisodesViewController()
        episodeController.podcast = favoritePodcast
        navigationController?.pushViewController(episodeController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let size = (collectionView.frame.width  - (3 * 16)) / 2
        return CGSize(width: size, height: size + 48)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 16
    }
}
