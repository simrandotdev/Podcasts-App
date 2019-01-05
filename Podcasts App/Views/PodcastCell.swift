import UIKit
import SDWebImage

class PodcastCell: UITableViewCell
{
    @IBOutlet
    weak var thumbnailImage: UIImageView!
    
    @IBOutlet
    weak var trackNameLabel: UILabel!
    
    @IBOutlet
    weak var artistNameLabel: UILabel!
    
    @IBOutlet
    weak var numberOfEpisodesLabel: UILabel!
    
    @IBOutlet
    weak var containerView: UIView!
    
    
    var podcast: Podcast! {
        didSet {
            guard let url = URL(string: podcast.artworkUrl600 ?? "") else { return }
            trackNameLabel.text = podcast.trackName
            artistNameLabel.text = podcast.artistName
            thumbnailImage.sd_setImage(with: url, completed: nil)
            numberOfEpisodesLabel.text = "\(podcast.trackCount ?? 0) episodes"
        }
    }
    
    
    override
    func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = .white
        containerView.backgroundColor = primaryLightColor
    }

    override
    func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
