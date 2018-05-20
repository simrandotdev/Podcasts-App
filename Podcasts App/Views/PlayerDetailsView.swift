import UIKit
import SDWebImage

class PlayerDetailsView : UIView
{
    var episode: Episode? {
        didSet {
            episodeTitleLabel.text = episode?.title
            authorLabel.text = episode?.author ?? ""
            guard let url = URL(string: episode?.thumbnail ?? "") else { return }
            episodeImageView.sd_setImage(with: url, completed: nil)
            
        }
    }
    
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    @IBAction func handleDismiss(_ sender: UIButton)
    {
        self.removeFromSuperview()
    }
    
}
