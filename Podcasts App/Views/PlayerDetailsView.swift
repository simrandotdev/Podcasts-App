import UIKit
import SDWebImage
import AVKit
import MediaPlayer

class PlayerDetailsView : UIView
{
    // MARK:- Properties
    var episode: Episode? {
        didSet {
            episodeTitleLabel.text = episode?.title
            miniTitleLabel.text = episode?.title
            authorLabel.text = episode?.author ?? ""
            setupNowPlayingInfo()
            playEpisode()
            
            setupImageInfoOnLockScreen()
        }
    }
    
    var playListEpisodes: [Episode]? = [Episode]()
    
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
    
    // MARK:- Initializers
    override
    func awakeFromNib()
    {
        super.awakeFromNib()
        setupRemoteControl()
        setupAudioSession()
        observePlayerCurrentTime()
        observePlayerStartPlaying()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize)))
        setupInterruptionObserver()
    }
    
    static func initFromNib() -> PlayerDetailsView
    {
        return Bundle.main.loadNibNamed("PlayerDetailsView", owner: self, options: nil)?.first as! PlayerDetailsView
    }
    
    // MARK:- IBActions
    @IBAction
    func handleDismiss(_ sender: UIButton)
    {
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController
        mainTabBarController?.minimizePlayerDetails()
    }
    
    @IBAction
    func handleCurrentTimeSliderChange(_ sender: Any)
    {
        let percentage = currentTimeSlider.value
        
        guard let duration = player.currentItem?.duration else { return }
        let durationInSeconds = CMTimeGetSeconds(duration)
        let seekTimeInSeconds = Float64(percentage) * Float64(durationInSeconds)
        let seekTime = CMTimeMakeWithSeconds(seekTimeInSeconds, Int32(NSEC_PER_SEC))
        player.seek(to: seekTime)
    }
    
    @IBAction
    func handleRewind(_ sender: Any)
    {
        let seekTime = CMTimeAdd(player.currentTime(), CMTimeMake(-15, 1))
        player.seek(to: seekTime)
    }
    
    @IBAction
    func handleForward(_ sender: Any)
    {
        let seekTime = CMTimeAdd(player.currentTime(), CMTimeMake(15, 1))
        player.seek(to: seekTime)
    }
    
    @IBAction
    func handleVolumeChanged(_ sender: Any)
    {
        player.volume = volumeSlider.value
    }
    
    @objc
    func handlePlayPause()
    {
        if player.timeControlStatus == .paused
        {
            play()
        }
        else
        {
            pause()
        }
    }
    
    @objc
    func handleTapMaximize()
    {
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController
        mainTabBarController?.maximizePlayerDetails(episode: nil, playListEpisodes: nil)
    }
    
    // MARK:- Private Methods
    fileprivate
    func playEpisode()
    {
        print("Trying to play episode at url: \(episode?.enclosure?.link ?? "")")
        guard let url = URL(string: self.episode?.enclosure?.link ?? "") else { return }
        
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        player.play()
        playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
    }
    
    fileprivate
    func play()
    {
        player.play()
        playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        enlargeEpisodeView()
    }
    
    fileprivate
    func pause()
    {
        player.pause()
        playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        miniPlayPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        shrinkEpisodeView()
    }
    
    fileprivate
    func enlargeEpisodeView()
    {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImageView.transform = .identity
        })
    }
    
    fileprivate
    func shrinkEpisodeView()
    {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            let scale: CGFloat = 0.7
            self.episodeImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        })
    }
    
    fileprivate
    func observePlayerCurrentTime()
    {
        let interval = CMTimeMake(1, 1)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] (time) in
            guard let duration = self?.player.currentItem?.duration else { return }
            if duration.flags.contains(CMTimeFlags.indefinite) { return }
            
            let currentTime = time.toDisplayString()
            let durationTime = duration.toDisplayString()
            
            self?.currentTimeLabel.text = currentTime
            self?.durationLabel.text = durationTime
            
            self?.setupLockScreenCurrentTime()
            
            self?.updateCurrentTimeSlider()
        }
    }
    
    fileprivate
    func updateCurrentTimeSlider()
    {
        let currentTimeSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(player.currentItem?.duration ?? CMTimeMake(1, 1))
        
        let percentage = currentTimeSeconds / durationSeconds
        currentTimeSlider.value = Float(percentage)
        
    }
    
    
    fileprivate
    func observePlayerStartPlaying()
    {
        // This let's up know when the episode started playing
        let time = CMTime(value: 1, timescale: 3)
        let times = [NSValue(time: time)]
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            print("Episode started playing")
            self?.enlargeEpisodeView()
        }
    }
    
    fileprivate
    func setupAudioSession()
    {
        // This makes the audio to work in background after enabling
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let sessionError {
            print("Failed to activate sessions: ", sessionError)
        }
    }
    
    fileprivate
    func setupRemoteControl()
    {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Play Command
        let sharedCommandCenter = MPRemoteCommandCenter.shared()
        sharedCommandCenter.playCommand.isEnabled = true
        sharedCommandCenter.playCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            self.play()
            return MPRemoteCommandHandlerStatus.success
        }
        
        // Pause command
        sharedCommandCenter.pauseCommand.isEnabled = true
        sharedCommandCenter.pauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            self.pause()
            return MPRemoteCommandHandlerStatus.success
        }
        
        // Toggle Play Pause
        sharedCommandCenter.togglePlayPauseCommand.isEnabled = true
        sharedCommandCenter.togglePlayPauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            self.handlePlayPause()
            
            return MPRemoteCommandHandlerStatus.success
        }
        
        // Next Track Command
        sharedCommandCenter.nextTrackCommand.addTarget(self, action: #selector(handleNextTrack))
        
        // Previous Track Command
        sharedCommandCenter.previousTrackCommand.addTarget(self, action: #selector(handlePreviousTrack))
    }
    
    @objc
    fileprivate
    func handleNextTrack()
    {
        print("Play next episode")
        
        if playListEpisodes?.count == 0 { return }
        
        guard let currentEpisodeIndex = playListEpisodes?.index(where: { (ep) -> Bool in
            return self.episode?.title == ep.title
        }) else { return }
        
        let nextEpisodeIndex = currentEpisodeIndex + 1
        
        if nextEpisodeIndex >= (self.playListEpisodes?.count)! { return }
        print("Next index", nextEpisodeIndex)
        if let nextEpisode = playListEpisodes?[nextEpisodeIndex]
        {
            self.episode = nextEpisode
        }
    }
    
    @objc
    fileprivate
    func handlePreviousTrack()
    {
        print("Play previous episode")
        if playListEpisodes?.count == 0 { return }
        
        guard let currentEpisodeIndex = playListEpisodes?.index(where: { (ep) -> Bool in
            return self.episode?.title == ep.title
        }) else { return }
        
        let previousEpisodeIndex = currentEpisodeIndex - 1
        
        if previousEpisodeIndex < 0 { return }
        print("Previous index", previousEpisodeIndex)
        
        if let previousEpisode = playListEpisodes?[previousEpisodeIndex]
        {
            self.episode = previousEpisode
        }
    }
    
    fileprivate
    func setupNowPlayingInfo()
    {
        var nowPlayingInfo = [String : Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = episode?.author
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate
    func setupImageInfoOnLockScreen()
    {
        // lock screen artwork setup code
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        
        // some modifications here
        let artwork = MPMediaItemArtwork(boundsSize: (miniEpisodeImageView.image?.size)!, requestHandler: { (_) -> UIImage in
            return UIImage(named: "appicon")!
        })
        nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
        
        // Set the modified info again
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate
    func setupLockScreenCurrentTime()
    {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        
        guard let currentItem = player.currentItem else { return }
        let durationInSeconds = CMTimeGetSeconds(currentItem.duration)
        nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = durationInSeconds
        
        let elapsedTime = CMTimeGetSeconds(player.currentTime())
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
    }
    
    fileprivate
    func setupInterruptionObserver()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioInterruption), name: .AVAudioSessionInterruption, object: nil)
    }
    
    @objc
    fileprivate
    func handleAudioInterruption(notification: Notification)
    {
        print("Interruption Observed")
        guard let userInfo = notification.userInfo else { return }
        guard let type = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        
        if type == AVAudioSessionInterruptionType.began.rawValue
        {
            print("Interruption begain...")
            pause()
        }
        else
        {
            print("Interruption ended...")
            play()
        }
    }
    
    // MARK:- IBOutlet
    @IBOutlet
    weak var maximizedStackView: UIStackView!
    
    @IBOutlet
    weak var minimizedStackView: UIStackView!
    
    @IBOutlet
    weak var miniFastForwardButton: UIButton!
    
    @IBOutlet
    weak var miniPlayPauseButton: UIButton!  {
        didSet {
            miniPlayPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    @IBOutlet
    weak var miniTitleLabel: UILabel!
    
    @IBOutlet
    weak var miniEpisodeImageView: UIImageView!  {
        didSet {
            self.shrinkEpisodeView()
            miniEpisodeImageView.layer.cornerRadius = 10
            miniEpisodeImageView.clipsToBounds = true
        }
    }
    
    @IBOutlet
    weak var currentTimeSlider: UISlider!
    
    @IBOutlet
    weak var durationLabel: UILabel!
    
    @IBOutlet
    weak var currentTimeLabel: UILabel!
    
    @IBOutlet
    weak var episodeImageView: UIImageView! {
        didSet {
            self.shrinkEpisodeView()
            episodeImageView.layer.cornerRadius = 10
            episodeImageView.clipsToBounds = true
        }
    }
    
    @IBOutlet
    weak var episodeTitleLabel: UILabel!
    
    @IBOutlet
    weak var authorLabel: UILabel!
    
    @IBOutlet
    weak var playPauseButton: UIButton! {
        didSet {
            playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    @IBOutlet
    weak var volumeSlider: UISlider!
    
}
