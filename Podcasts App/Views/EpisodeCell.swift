import UIKit
import SDWebImage

class EpisodeCell: UITableViewCell
{
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publishedDateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var episode : Episode! {
        didSet {
            titleLabel.text = episode?.title
            publishedDateLabel.text = episode?.pubDate
            descriptionLabel.text = episode?.description
            
            guard let url = URL(string: episode?.thumbnail ?? "") else { return }
            thumbnailImageView.sd_setImage(with: url, completed: nil)
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }
}

