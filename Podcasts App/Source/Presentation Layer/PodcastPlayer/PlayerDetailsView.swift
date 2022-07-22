import UIKit
import SDWebImage
import AVKit
import MediaPlayer
import Resolver

class PlayerDetailsView : UIView {

    
    // MARK:- UI Elements
    
    
    @IBOutlet weak var maximizedStackView: UIStackView!
    @IBOutlet weak var minimizedStackView: UIStackView!
    @IBOutlet weak var miniFastForwardButton: UIButton!
    @IBOutlet weak var miniTitleLabel: UILabel!
    @IBOutlet weak var currentTimeSlider: UISlider!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet var blankViewBetweenMediaPlayerControls: [UIView]!
    @IBOutlet weak var miniPlayPauseButton: UIButton!  {
        
        didSet {
            
            miniPlayPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    @IBOutlet weak var miniEpisodeImageView: UIImageView!  {
        
        didSet {
            
            self.shrinkEpisodeView()
            miniEpisodeImageView.layer.cornerRadius = 10
            miniEpisodeImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var episodeImageView: UIImageView! {
        
        didSet {
            
            self.shrinkEpisodeView()
            episodeImageView.layer.cornerRadius = 10
            episodeImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var playPauseButton: UIButton! {
        
        didSet {
            
            playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    
    // MARK:- Properties
    
    
    public var minimizePlayerDetails: (() -> Void)?
    
    
    public var episodeViewModel: EpisodeViewModel? {
        didSet {
            
            episodeTitleLabel.text = episodeViewModel?.title
            miniTitleLabel.text = episodeViewModel?.title
            authorLabel.text = episodeViewModel?.author ?? ""
            
            guard let url = URL(string: episodeViewModel?.imageUrl ?? "") else { return }
            episodeImageView.sd_setImage(with: url, completed: nil)
            miniEpisodeImageView.sd_setImage(with: url, completed: nil)
            
            setupNowPlayingInfo()
            setupAudioSession()
            playEpisode()
            setupImageInfoOnLockScreen()

            // TODO: add the episode to history here
            Task {
                guard let episode = self.episodeViewModel else { return }
                try await episodesRepository.saveInHistory(episode: Episode(episodeViewModel: episode))
            }
        }
    }
    
    public var playListEpisodes: [EpisodeViewModel]? = [EpisodeViewModel]()
    
    public var thumbnail: String? {
        
        didSet {
            
            guard let url = URL(string: thumbnail ?? "") else { return }
            episodeImageView.sd_setImage(with: url, completed: nil)
            miniEpisodeImageView.sd_setImage(with: url, completed: nil)
        }
    }
    
    public var maximizePlayer: ((EpisodeViewModel?, [EpisodeViewModel]?) -> Void)?
    
    
    // MARK: - Dependencies
    
    
    private let player: AVPlayer = {
        
        let player = AVPlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        return player
    }()
    
    @Injected private var episodesRepository: EpisodesRepository
    
    // MARK:- Initializers
    
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        setupUI()        
        setupRemoteControl()
        observePlayerCurrentTime()
        observePlayerStartPlaying()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize)))
        setupInterruptionObserver()
    }
    
    
    static func initFromNib() -> PlayerDetailsView {
        return Bundle.main.loadNibNamed("PlayerDetailsView", owner: self, options: nil)?.first as! PlayerDetailsView
    }
    
    
    // MARK:- IBActions
    
    
    @IBAction func handleDismiss(_ sender: UIButton) {
        
        minimizePlayerDetails?()
    }
    
    @IBAction func closePlayer(_ sender: UIButton) {
        
        UIView.animate(withDuration: 5) {
            self.isHidden = true
            self.player.pause()
        }
    }
    
    @IBAction func handleCurrentTimeSliderChange(_ sender: Any) {
        
        guard let duration = player.currentItem?.duration else { return }
        let percentage = currentTimeSlider.value
        let durationInSeconds = CMTimeGetSeconds(duration)
        let seekTimeInSeconds = Float64(percentage) * Float64(durationInSeconds)
        let seekTime = CMTimeMakeWithSeconds(seekTimeInSeconds, preferredTimescale: Int32(NSEC_PER_SEC))
        player.seek(to: seekTime)
    }
    
    @IBAction func handleRewind(_ sender: Any) {
        
        let seekTime = CMTimeAdd(player.currentTime(), CMTimeMake(value: -15, timescale: 1))
        player.seek(to: seekTime)
    }
    
    @IBAction func handleForward(_ sender: Any) {
        
        let seekTime = CMTimeAdd(player.currentTime(), CMTimeMake(value: 15, timescale: 1))
        player.seek(to: seekTime)
    }
    
    @objc func handlePlayPause() {
        
        if player.timeControlStatus == .paused { play() }
        else { pause() }
    }
    
    @objc func handleTapMaximize() {
        
        maximizePlayer?(nil, nil)
    }
    
    @objc func doPlayPause(_ event:MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        self.handlePlayPause()
        return .success
    }
    
    @objc func doPlay(_ event:MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        self.play()
        // Sets the time correctly on lock screen when resumed from pause.
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1
        return .success
    }
    
    @objc func doPause(_ event:MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        self.pause()
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0
        return .success
    }
    
    @objc fileprivate func handleNextTrack(_ event:MPRemoteCommandEvent)  -> MPRemoteCommandHandlerStatus {
        
        if playListEpisodes?.count == 0 { return .noActionableNowPlayingItem}
        
        guard let currentEpisodeIndex = playListEpisodes?.firstIndex(where: { (ep) -> Bool in
            
            return self.episodeViewModel?.title == ep.title
        }) else { return .commandFailed}
        
        let nextEpisodeIndex = currentEpisodeIndex + 1
        if nextEpisodeIndex >= (self.playListEpisodes?.count)! { return .noActionableNowPlayingItem }
        if let nextEpisode = playListEpisodes?[nextEpisodeIndex] {
            
            self.episodeViewModel = nextEpisode
        }
        return .success
    }
    
    @objc fileprivate func handlePreviousTrack(_ event:MPRemoteCommandEvent)  -> MPRemoteCommandHandlerStatus {
        
        if playListEpisodes?.count == 0 { return .noActionableNowPlayingItem}
        
        guard let currentEpisodeIndex = playListEpisodes?.firstIndex(where: { (ep) -> Bool in
            
            return self.episodeViewModel?.title == ep.title
        }) else {
            
            return .noActionableNowPlayingItem
        }
        
        let previousEpisodeIndex = currentEpisodeIndex - 1
        if previousEpisodeIndex < 0 { return .noActionableNowPlayingItem }
        if let previousEpisode = playListEpisodes?[previousEpisodeIndex] {
            
            self.episodeViewModel = previousEpisode
        }
        return .success
    }
    
    
    @objc fileprivate func handleAudioInterruption(notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        guard let type = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        
        if type == AVAudioSession.InterruptionType.began.rawValue {
            
            pause()
        }
        else {
            
            guard let options = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            
            if options == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                
                play()
            }
        }
    }
    
    
    // MARK:- Private Methods
    
    
    fileprivate func playEpisode() {
        
        guard let url = URL(string: self.episodeViewModel?.streamUrl ?? "") else { return }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        play()
    }
    
    fileprivate func play() {
        
        player.play()
        guard let key = episodeViewModel?.streamUrl else { return }
        
        let oldTime = UserDefaults.standard.integer(forKey: key)
        player.seek(to: CMTimeMakeWithSeconds(Float64(oldTime), preferredTimescale: 60000))
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        miniPlayPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        enlargeEpisodeView()
    }
    
    fileprivate func pause() {
        
        player.pause()
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        miniPlayPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        shrinkEpisodeView()
    }
    
    fileprivate func enlargeEpisodeView() {
        
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImageView.transform = .identity
        })
    }
    
    fileprivate func shrinkEpisodeView() {
        
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            let scale: CGFloat = 0.7
            self.episodeImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        })
    }
    
    fileprivate func observePlayerCurrentTime() {
        
        let interval = CMTimeMake(value: 1, timescale: 1)
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
    
    fileprivate func updateCurrentTimeSlider() {
        
        let currentTimeSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(player.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1))
        
        let percentage = currentTimeSeconds / durationSeconds
        currentTimeSlider.value = Float(percentage)
        if(Int(currentTimeSeconds) % 5 == 0) {
            
            guard let key = episodeViewModel?.streamUrl else {
                return
            }
            UserDefaults.standard.set(Int(currentTimeSeconds), forKey: key)
        }
    }
    
    
    fileprivate func observePlayerStartPlaying() {
        
        // This let's up know when the episode started playing
        let time = CMTime(value: 1, timescale: 3)
        let times = [NSValue(time: time)]
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            
            self?.enlargeEpisodeView()
        }
    }
    
    fileprivate func setupAudioSession() {
        
        // This makes the audio to work in background after enabling
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)), mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let sessionError {
            err("Failed to activate sessions: \(sessionError)")
        }
    }
    
    fileprivate func setupRemoteControl() {
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let sharedCommandCenter = MPRemoteCommandCenter.shared()
        // Play Command
        setupLockScreenPlayCommand(sharedCommandCenter)
        // Pause command
        setupLockScreenPauseCommand(sharedCommandCenter)
        // Toggle Play Pause
        setupLockScreenTogglePlayPause(sharedCommandCenter)
        // Next Track Command
        sharedCommandCenter.nextTrackCommand.addTarget(self, action: #selector(handleNextTrack))
        // Previous Track Command
        sharedCommandCenter.previousTrackCommand.addTarget(self, action: #selector(handlePreviousTrack))
    }
    
    fileprivate func setupLockScreenPlayCommand(_ sharedCommandCenter: MPRemoteCommandCenter) {
        
        sharedCommandCenter.playCommand.isEnabled = true
        sharedCommandCenter.playCommand.addTarget(self, action: #selector(doPlayPause(_:)))
    }
    
    fileprivate func setupLockScreenPauseCommand(_ sharedCommandCenter: MPRemoteCommandCenter) {
        
        sharedCommandCenter.pauseCommand.isEnabled = true
        sharedCommandCenter.pauseCommand.addTarget(self, action: #selector(doPause(_:)))
    }
    
    fileprivate func setupLockScreenTogglePlayPause(_ sharedCommandCenter: MPRemoteCommandCenter) {
        
        sharedCommandCenter.togglePlayPauseCommand.isEnabled = true
        sharedCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(doPlayPause(_:)))
    }
    
    fileprivate func setupNowPlayingInfo() {
        
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = episodeViewModel?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = episodeViewModel?.author
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate func setupImageInfoOnLockScreen() {
        
        guard let episodeImageView = miniEpisodeImageView.image else { return }
        
        // lock screen artwork setup code
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        // some modifications here
        let artwork = MPMediaItemArtwork(boundsSize: episodeImageView.size, requestHandler: { (_) -> UIImage in
            return UIImage(named: "appicon")!
        })
        nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
        // Set the modified info again
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate func setupLockScreenCurrentTime() {
        
        guard let currentItem = player.currentItem else { return }
        
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        
        let durationInSeconds = CMTimeGetSeconds(currentItem.duration)
        nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = durationInSeconds
    
        let elapsedTime = CMTimeGetSeconds(player.currentTime())
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
    
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate func setupInterruptionObserver() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    
    // MARK: UI Setup
    
    
    func setupUI() {
        
        backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.heightAnchor.constraint(equalTo: heightAnchor),
            blurView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
        
        currentTimeSlider.tintColor = .systemGray6
        
        blankViewBetweenMediaPlayerControls.forEach { $0.backgroundColor = .clear }
        
        episodeImageView.layer.cornerRadius = 20
        episodeImageView.layer.masksToBounds = true
        
        miniEpisodeImageView.layer.cornerRadius = 10
        miniEpisodeImageView.layer.masksToBounds = true
        
        miniTitleLabel.font = Theme.Font.title2
        authorLabel.font = Theme.Font.title3
        durationLabel.font = Theme.Font.footnote
        currentTimeLabel.font = Theme.Font.footnote
        
    }
}

// Helper function inserted by Swift 4.2 migrator.

fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
    
    return input.rawValue
}
