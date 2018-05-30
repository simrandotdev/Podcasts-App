import UIKit
import SDWebImage
import AVKit

class PlayerDetailsView : UIView
{
    var episode: Episode? {
        didSet {
            episodeTitleLabel.text = episode?.title
            miniTitleLabel.text = episode?.title
            authorLabel.text = episode?.author ?? ""
            playEpisode()
        }
    }
    
    var thumbnail: String? {
        didSet {
            guard let url = URL(string: thumbnail ?? "") else { return }
            episodeImageView.sd_setImage(with: url, completed: nil)
            miniEpisodeImageView.sd_setImage(with: url, completed: nil)
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
        
        observePlayerCurrentTime()
        observePlayerStartPlaying()
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize)))
    }
    
    static func initFromNib() -> PlayerDetailsView
    {
        return Bundle.main.loadNibNamed("PlayerDetailsView", owner: self, options: nil)?.first as! PlayerDetailsView
    }
    
    // MARK: IBActions
    @IBOutlet weak var maximizedStackView: UIStackView!
    @IBOutlet weak var minimizedStackView: UIStackView!
    
    @IBOutlet weak var miniFastForwardButton: UIButton!
    @IBOutlet weak var miniPlayPauseButton: UIButton!  {
        didSet {
            miniPlayPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    @IBOutlet weak var miniTitleLabel: UILabel!
    @IBOutlet weak var miniEpisodeImageView: UIImageView!  {
        didSet {
            self.shrinkEpisodeView()
            miniEpisodeImageView.layer.cornerRadius = 10
            miniEpisodeImageView.clipsToBounds = true
        }
    }
    
    @IBOutlet weak var currentTimeSlider: UISlider!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
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
    @IBOutlet weak var volumeSlider: UISlider!
    
    @IBAction func handleDismiss(_ sender: UIButton)
    {
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController
        mainTabBarController?.minimizePlayerDetails()
    }
    
    @IBAction func handleCurrentTimeSliderChange(_ sender: Any)
    {
        let percentage = currentTimeSlider.value
        
        guard let duration = player.currentItem?.duration else { return }
        let durationInSeconds = CMTimeGetSeconds(duration)
        let seekTimeInSeconds = Float64(percentage) * Float64(durationInSeconds)
        let seekTime = CMTimeMakeWithSeconds(seekTimeInSeconds, Int32(NSEC_PER_SEC))
        player.seek(to: seekTime)
    }
    
    @IBAction func handleRewind(_ sender: Any)
    {
        let seekTime = CMTimeAdd(player.currentTime(), CMTimeMake(-15, 1))
        player.seek(to: seekTime)
    }
    
    @IBAction func handleForward(_ sender: Any)
    {
        let seekTime = CMTimeAdd(player.currentTime(), CMTimeMake(15, 1))
        player.seek(to: seekTime)
    }
    
    @IBAction func handleVolumeChanged(_ sender: Any)
    {
        player.volume = volumeSlider.value
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
    
    @objc func handleTapMaximize()
    {
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController
        mainTabBarController?.maximizePlayerDetails(episode: nil)
    }
    
    fileprivate func playEpisode()
    {
        print("Trying to play episode at url: \(episode?.enclosure?.link ?? "")")
        guard let url = URL(string: self.episode?.enclosure?.link ?? "") else { return }
        
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        player.play()
        playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
    }
    
    fileprivate func play()
    {
        player.play()
        playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        enlargeEpisodeView()
    }
    
    fileprivate func pause()
    {
        player.pause()
        playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        miniPlayPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
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
    
    fileprivate func observePlayerCurrentTime()
    {
        let interval = CMTimeMake(1, 1)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] (time) in
            guard let duration = self?.player.currentItem?.duration else { return }
            if duration.flags.contains(CMTimeFlags.indefinite) { return }
            
            let currentTime = time.toDisplayString()
            let durationTime = duration.toDisplayString()
            
            self?.currentTimeLabel.text = currentTime
            self?.durationLabel.text = durationTime
            
            self?.updateCurrentTimeSlider()
        }
    }
    
    fileprivate func updateCurrentTimeSlider()
    {
        let currentTimeSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(player.currentItem?.duration ?? CMTimeMake(1, 1))
        
        let percentage = currentTimeSeconds / durationSeconds
        currentTimeSlider.value = Float(percentage)
        
    }
    
    
    fileprivate func observePlayerStartPlaying()
    {
        // This let's up know when the episode started playing
        let time = CMTime(value: 1, timescale: 3)
        let times = [NSValue(time: time)]
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            print("Episode started playing")
            self?.enlargeEpisodeView()
        }
    }
    
}
