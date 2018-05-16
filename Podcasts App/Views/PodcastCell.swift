import UIKit

class PodcastCell: UITableViewCell {

    @IBOutlet weak var podcastThumbnailImage: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var numberOfEpisodesLabel: UILabel!
    
    var podcast: Podcast! {
        didSet {
            trackNameLabel.text = podcast.trackName
            artistNameLabel.text = podcast.artistName
            podcastThumbnailImage.image = #imageLiteral(resourceName: "appicon")
            numberOfEpisodesLabel.text = "\(0) episodes"
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
