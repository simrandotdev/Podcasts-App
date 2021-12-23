import UIKit
import SDWebImage

class PodcastCell: UITableViewCell {
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var numberOfEpisodesLabel: UILabel!
    
    var podcast: PodcastViewModel! {
        didSet {
            guard let url = URL(string: podcast.image) else { return }
            trackNameLabel.text = podcast.title
            artistNameLabel.text = podcast.author
            thumbnailImage.sd_setImage(with: url, completed: nil)
            numberOfEpisodesLabel.text = "\(podcast.numberOfEpisodes) episodes"
        }
    }
    
    override func awakeFromNib(){
        super.awakeFromNib()
        backgroundColor = Theme.Color.systemBackgroundColor
        thumbnailImage?.layer.cornerRadius = 10
        thumbnailImage?.layer.masksToBounds = true
    }
}
