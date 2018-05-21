import UIKit
import SDWebImage
import AVKit

class PlayerDetailsView : UIView
{
    var episode: Episode? {
        didSet {
            episodeTitleLabel.text = episode?.title
            authorLabel.text = episode?.author ?? ""
            playEpisode()
        }
    }
    
    var thumbnail: String? {
        didSet {
            guard let url = URL(string: thumbnail ?? "") else { return }
            episodeImageView.sd_setImage(with: url, completed: nil)
        }
    }
    
    let player: AVPlayer = {
        let player = AVPlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        return player
    }()
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        // This let's up know when the episode started playing
        let time = CMTime(value: 1, timescale: 3)
        let times = [NSValue(time: time)]
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) {
            print("Episode started playing")
            self.enlargeEpisodeView()
        }
    }
    
    @IBOutlet weak var episodeImageView: UIImageView! {
        didSet {
            self.shrinkEpisodeView()
            episodeImageView.layer.cornerRadius = 10
            episodeImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton! {
        didSet {
            playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    @IBAction func handleDismiss(_ sender: UIButton)
    {
        self.removeFromSuperview()
    }
    
    @objc func handlePlayPause()
    {
        print("Handle Play Pause")
        if player.timeControlStatus == .paused
        {
            play()
        }
        else
        {
            pause()
        }
    }
    
    fileprivate func playEpisode()
    {
        print("Trying to play episode at url: \(episode?.enclosure?.link ?? "")")
        guard let url = URL(string: self.episode?.enclosure?.link ?? "") else { return }
        
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        player.play()
        playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
    }
    
    fileprivate func play()
    {
        player.play()
        playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        enlargeEpisodeView()
    }
    
    fileprivate func pause()
    {
        player.pause()
        playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        shrinkEpisodeView()
    }
    
    fileprivate func enlargeEpisodeView()
    {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImageView.transform = .identity
        })
    }
    
    fileprivate func shrinkEpisodeView()
    {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            let scale: CGFloat = 0.7
            self.episodeImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        })
    }
    
}
