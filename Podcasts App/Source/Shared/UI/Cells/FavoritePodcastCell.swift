import UIKit

class FavoritePodcastCell : UICollectionViewCell {
    
    
    // MARK:- UI properties
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var artistNameLabel: UILabel!
    @IBOutlet weak var backgroundTitleView: UIView!
   
    // MARK:- Setups
    fileprivate func stylizeUI() {
        backgroundColor = Theme.Color.systemBackgroundColor
        layer.cornerRadius = 2.0
        layer.masksToBounds = true
        
        nameLabel.text = ""
        nameLabel.font = Theme.Font.body
        nameLabel.numberOfLines = 2
        
        artistNameLabel.text = ""
        artistNameLabel.font = Theme.Font.caption1
        
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        
        backgroundTitleView.alpha = 0.8
    }
    
    func setupCell(podcast: PodcastViewModel) {
        stylizeUI()
        guard let imageUrl = URL(string: podcast.image ?? "") else { return }
        imageView.sd_setImage(with: imageUrl)
        nameLabel.text = podcast.title
        artistNameLabel.text = podcast.author
    }
}
