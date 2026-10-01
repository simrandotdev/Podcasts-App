import AVKit
import Combine
import MediaPlayer
import Resolver

/// Owns playback independently of the currently visible screen or player size.
@MainActor
final class PlaybackController: ObservableObject {
    @Published private(set) var episode: EpisodeViewModel?
    @Published private(set) var queue: [EpisodeViewModel] = []
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published var errorMessage: String?

    private let player: AVPlayer
    private let defaults: UserDefaults
    private let saveHistory: (Episode) async throws -> Void
    private let systemPlaybackEnabled: Bool
    private var session: MPNowPlayingSession?
    private var timeObserver: Any?
    private var subscriptions = Set<AnyCancellable>()
    private var itemSubscription: AnyCancellable?
    private var artworkTask: Task<Void, Never>?
    private var historyTask: Task<Void, Never>?
    private var commandTargets: [(MPRemoteCommand, Any)] = []
    private var resumeAfterInterruption = false
    private var isSeeking = false
    private var seekGeneration = 0

    init(player: AVPlayer = AVPlayer(), defaults: UserDefaults = .standard,
         systemPlaybackEnabled: Bool = true,
         saveHistory: @escaping (Episode) async throws -> Void = { episode in
             let repository: EpisodesRepository = Resolver.resolve()
             try await repository.saveInHistory(episode: episode)
         }) {
        self.player = player
        self.defaults = defaults
        self.systemPlaybackEnabled = systemPlaybackEnabled
        self.saveHistory = saveHistory
        player.automaticallyWaitsToMinimizeStalling = true
        observePlayer()
        if systemPlaybackEnabled {
            let session = MPNowPlayingSession(players: [player])
            session.automaticallyPublishesNowPlayingInfo = true
            self.session = session
            configureRemoteCommands(session.remoteCommandCenter)
            observeAudioSession()
        }
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        artworkTask?.cancel()
        historyTask?.cancel()
        for (command, target) in commandTargets { command.removeTarget(target) }
    }

    var currentIndex: Int? {
        queue.firstIndex { $0.streamUrl == episode?.streamUrl }
    }

    var canPlayPrevious: Bool { (currentIndex ?? 0) > 0 }
    var canPlayNext: Bool {
        guard let currentIndex else { return false }
        return currentIndex + 1 < queue.count
    }

    func load(_ episode: EpisodeViewModel, queue: [EpisodeViewModel], autoplay: Bool = true) {
        guard let url = URL(string: episode.fileUrl ?? episode.streamUrl),
              ["http", "https", "file"].contains(url.scheme?.lowercased() ?? "") else {
            errorMessage = "This episode does not have a valid audio URL."
            return
        }
        saveProgress()
        artworkTask?.cancel()
        seekGeneration += 1
        isSeeking = false
        player.pause()
        self.episode = episode
        self.queue = queue.contains(where: { $0.streamUrl == episode.streamUrl }) ? queue : [episode] + queue
        isPlaying = false
        isBuffering = false
        errorMessage = nil
        duration = 0
        currentTime = Self.validTime(defaults.double(forKey: episode.streamUrl))

        let item = AVPlayerItem(url: url)
        item.nowPlayingInfo = Self.nowPlayingInfo(for: episode)
        player.replaceCurrentItem(with: item)
        itemSubscription = item.publisher(for: \.status).receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] status in
                guard let self, let item, item === self.player.currentItem else { return }
                if status == .readyToPlay {
                    self.duration = Self.validTime(item.duration.seconds)
                    // Restore only when loading a new item, never on ordinary play/pause.
                    let saved = Self.validTime(self.defaults.double(forKey: episode.streamUrl))
                    self.seek(to: self.duration > 0 && saved >= self.duration ? 0 : saved)
                } else if status == .failed {
                    self.pause()
                    self.errorMessage = item.error?.localizedDescription ?? "This episode could not be played."
                }
            }
        if systemPlaybackEnabled { loadArtwork(for: episode, item: item) }
        let previousHistoryTask = historyTask
        historyTask = Task { [saveHistory] in
            // Serialize writes so quickly selecting episodes preserves their history order.
            await previousHistoryTask?.value
            do {
                try await saveHistory(Episode(episodeViewModel: episode))
                NotificationCenter.default.post(name: .playbackHistoryChanged, object: nil)
            } catch {
                self.errorMessage = "Unable to save listening history: \(error.localizedDescription)"
            }
        }
        updateRemoteAvailability()
        if autoplay { play() }
    }

    func play() {
        guard episode != nil else { return }
        if player.currentItem?.status == .failed, let episode {
            load(episode, queue: queue)
            return
        }
        if systemPlaybackEnabled {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
                try AVAudioSession.sharedInstance().setActive(true)
                session?.becomeActiveIfPossible(completion: nil)
            } catch {
                errorMessage = "Unable to start audio: \(error.localizedDescription)"
                return
            }
        }
        if duration > 0 && currentTime >= duration { seek(to: 0) }
        isPlaying = true
        player.play()
    }

    func pause() {
        isPlaying = false
        isBuffering = false
        player.pause()
        saveProgress()
    }

    func togglePlayback() { isPlaying ? pause() : play() }

    func seek(to seconds: Double) {
        guard episode != nil, seconds.isFinite else { return }
        let target = max(0, duration > 0 ? min(seconds, duration) : seconds)
        currentTime = target
        isSeeking = true
        seekGeneration += 1
        let generation = seekGeneration
        saveProgress()
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero,
                    toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.seekGeneration == generation else { return }
                self.isSeeking = false
            }
        }
    }

    func skip(by seconds: Double) { seek(to: currentTime + seconds) }

    func next() {
        guard canPlayNext, let index = currentIndex else { return }
        load(queue[index + 1], queue: queue)
    }

    func previous() {
        guard canPlayPrevious, let index = currentIndex else { return }
        load(queue[index - 1], queue: queue)
    }

    func close() {
        pause()
        artworkTask?.cancel()
        itemSubscription = nil
        seekGeneration += 1
        isSeeking = false
        player.replaceCurrentItem(with: nil)
        episode = nil
        queue = []
        currentTime = 0
        duration = 0
        updateRemoteAvailability()
        if systemPlaybackEnabled {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    func saveProgress() {
        guard let episode, currentTime.isFinite else { return }
        // Keep the legacy stream-URL key so existing users retain their resume positions.
        defaults.set(max(0, currentTime), forKey: episode.streamUrl)
    }

    static func validTime(_ seconds: Double) -> Double {
        seconds.isFinite ? max(0, seconds) : 0
    }

    private func observePlayer() {
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600),
                                                       queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self, self.episode != nil, !self.isSeeking,
                      self.player.currentItem?.status == .readyToPlay else { return }
                self.currentTime = Self.validTime(time.seconds)
                self.duration = Self.validTime(self.player.currentItem?.duration.seconds ?? 0)
                self.saveProgress()
            }
        }
        player.publisher(for: \.timeControlStatus).receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.isBuffering = self.isPlaying && status == .waitingToPlayAtSpecifiedRate
            }.store(in: &subscriptions)
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self, let item = notification.object as? AVPlayerItem,
                      item === self.player.currentItem else { return }
                self.pause()
                if let episode = self.episode { self.defaults.set(0, forKey: episode.streamUrl) }
            }.store(in: &subscriptions)
    }

    private func observeAudioSession() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                      let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
                if type == .began {
                    self.resumeAfterInterruption = self.isPlaying
                    self.pause()
                } else {
                    let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                    let shouldResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
                    if self.resumeAfterInterruption && shouldResume { self.play() }
                    self.resumeAfterInterruption = false
                }
            }.store(in: &subscriptions)
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue { self?.pause() }
            }.store(in: &subscriptions)
    }

    private func configureRemoteCommands(_ center: MPRemoteCommandCenter) {
        register(center.playCommand) { $0.play() }
        register(center.pauseCommand) { $0.pause() }
        register(center.togglePlayPauseCommand) { $0.togglePlayback() }
        register(center.nextTrackCommand) { $0.next() }
        register(center.previousTrackCommand) { $0.previous() }
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.preferredIntervals = [15]
        register(center.skipForwardCommand) { $0.skip(by: 15) }
        register(center.skipBackwardCommand) { $0.skip(by: -15) }
        let target = center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let position = event.positionTime
            Task { @MainActor in self?.seek(to: position) }
            return .success
        }
        commandTargets.append((center.changePlaybackPositionCommand, target))
        updateRemoteAvailability()
    }

    private func register(_ command: MPRemoteCommand, action: @escaping @MainActor (PlaybackController) -> Void) {
        let target = command.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self, self.episode != nil else { return }
                action(self)
            }
            return .success
        }
        commandTargets.append((command, target))
    }

    private func updateRemoteAvailability() {
        guard let center = session?.remoteCommandCenter else { return }
        for (command, _) in commandTargets { command.isEnabled = episode != nil }
        center.nextTrackCommand.isEnabled = canPlayNext
        center.previousTrackCommand.isEnabled = canPlayPrevious
    }

    private static func nowPlayingInfo(for episode: EpisodeViewModel) -> [String: Any] {
        [MPMediaItemPropertyTitle: episode.title,
         MPMediaItemPropertyArtist: episode.author,
         MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue]
    }

    private func loadArtwork(for episode: EpisodeViewModel, item: AVPlayerItem) {
        // MPNowPlayingSession publishes the item's nowPlayingInfo, including artwork, to the
        // lock screen and Control Center. AVPlayerItem.externalMetadata is not usable on iOS 16/17.
        artworkTask = Task { [weak self, weak item] in
            guard let url = URL(string: episode.imageUrl ?? ""),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  !Task.isCancelled, let self, let item, item === self.player.currentItem,
                  let image = UIImage(data: data) else { return }
            var info = Self.nowPlayingInfo(for: episode)
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            item.nowPlayingInfo = info
        }
    }
}

extension Notification.Name {
    static let playbackHistoryChanged = Notification.Name("playbackHistoryChanged")
}
