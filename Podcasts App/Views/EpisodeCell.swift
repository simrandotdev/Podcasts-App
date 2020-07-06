import UIKit
import SDWebImage

class EpisodeCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publishedDateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var episode : Episode! {
        didSet {
            titleLabel.text = episode.title
            descriptionLabel.text = episode.description
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            publishedDateLabel.text = dateFormatter.string(from: episode.pubDate)
            
            guard let url = URL(string: episode?.imageUrl ?? "") else { return }
            thumbnailImageView.sd_setImage(with: url, completed: nil)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .systemBackground
    }
}

