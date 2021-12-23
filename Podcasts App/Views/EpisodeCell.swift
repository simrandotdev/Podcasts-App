import UIKit
import SDWebImage

class EpisodeCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publishedDateLabel: UILabel!
    
    var episode : EpisodeViewModel! {
        didSet {
            titleLabel.text = episode.title
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            publishedDateLabel.text = dateFormatter.string(from: episode.pubDate)
            
            guard let url = URL(string: episode?.imageUrl ?? "") else { return }
            thumbnailImageView.sd_setImage(with: url, completed: nil)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = Theme.Color.systemBackgroundColor
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.layer.masksToBounds = true
    }
    
    func configure(withViewModel episodeViewModel: EpisodeViewModel, podcastImageURL: String) {
        titleLabel.text = episodeViewModel.title
        publishedDateLabel.text = episodeViewModel.pubDate.toString(withFormat: "MMM dd, yyyy")
        
        guard let url = URL(string: episodeViewModel.imageUrl ?? "") else { return }
        thumbnailImageView.sd_setImage(with: url, completed: nil)
    }
    
}
