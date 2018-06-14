import UIKit

class FavoriteViewController: UICollectionViewController
{
    private let cellId = "favoritesCellId"
    
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        setupCollectionView()
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
        return 50
    }
    
    override
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FavoritePodcastCell

        return cell
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
