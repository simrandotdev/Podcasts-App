import AVKit
import MediaPlayer
import Observation
import Resolver

/// Owns playback independently of the currently visible screen or player size. Views reach it
/// through `PlayerViewModel`.
@MainActor
@Observable
final class PlaybackManager {
    /// One player for the whole app, so playback survives navigation.
    static let shared = PlaybackManager()

    private(set) var episode: Episode?
    private(set) var queue: [Episode] = []
    private(set) var isPlaying = false
    private(set) var isBuffering = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var playbackRate: Float = 1
    var errorMessage: String?
    /// Goes up each time listening time is recorded, so views that show `listeningStats` update.
    private(set) var listeningStatsRevision = 0

    private let player: AVPlayer
    private let defaults: UserDefaults
    private let saveHistory: (Episode) async throws -> Void
    /// The downloaded copy of an episode, by stream URL, to play instead of streaming.
    private let localFile: (String) -> URL?
    private let systemPlaybackEnabled: Bool
    @ObservationIgnored private var session: MPNowPlayingSession?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var itemStatusObservation: NSKeyValueObservation?
    @ObservationIgnored private var timeControlObservation: NSKeyValueObservation?
    /// Tasks that read system notifications for as long as the manager exists.
    @ObservationIgnored private var notificationTasks: [Task<Void, Never>] = []
    @ObservationIgnored private var artworkTask: Task<Void, Never>?
    @ObservationIgnored private var historyTask: Task<Void, Never>?
    @ObservationIgnored private var commandTargets: [(MPRemoteCommand, Any)] = []
    @ObservationIgnored private var resumeAfterInterruption = false
    @ObservationIgnored private var isSeeking = false
    @ObservationIgnored private var seekGeneration = 0
    /// Total and per-day listening time, for the Settings screen.
    let listeningStats: ListeningStats
    /// When listening time was last counted; nil whenever audio isn't advancing normally.
    @ObservationIgnored private var lastListeningTick: Date?

    static let playbackRates: [Float] = [1, 1.25, 1.5, 2]
    private static let playbackRateKey = "playbackRate"

    init(player: AVPlayer = AVPlayer(), defaults: UserDefaults = .standard,
         systemPlaybackEnabled: Bool = true,
         localFile: @escaping (String) -> URL? = { DownloadStore.standard.existingFile(for: $0) },
         saveHistory: @escaping (Episode) async throws -> Void = { episode in
             let episodes: EpisodesManaging = Resolver.resolve()
             try await episodes.saveInHistory(episode: episode)
         }) {
        self.player = player
        self.defaults = defaults
        self.listeningStats = ListeningStats(defaults: defaults)
        self.systemPlaybackEnabled = systemPlaybackEnabled
        self.saveHistory = saveHistory
        self.localFile = localFile
        player.automaticallyWaitsToMinimizeStalling = true
        let savedRate = defaults.float(forKey: Self.playbackRateKey)
        playbackRate = Self.playbackRates.contains(savedRate) ? savedRate : 1
        // play() starts at defaultRate, so the chosen speed survives pause/resume and new episodes.
        player.defaultRate = playbackRate
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
        for task in notificationTasks { task.cancel() }
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

    func load(_ episode: Episode, queue: [Episode], autoplay: Bool = true) {
        // Prefer a downloaded copy so the episode plays offline.
        guard let url = localFile(episode.streamUrl) ?? URL(string: episode.fileUrl ?? episode.streamUrl),
              ["http", "https", "file"].contains(url.scheme?.lowercased() ?? "") else {
            errorMessage = "This episode does not have a valid audio URL."
            return
        }
        saveProgress()
        lastListeningTick = nil
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
        // Keep voices at their natural pitch when playing faster.
        item.audioTimePitchAlgorithm = .timeDomain
        item.nowPlayingInfo = Self.nowPlayingInfo(for: episode)
        player.replaceCurrentItem(with: item)
        // KVO reports on whichever thread changed the status, so handle it on the main actor.
        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            let status = item.status
            Task { @MainActor in
                guard let self, item === self.player.currentItem else { return }
                self.itemStatusChanged(status, item: item, episode: episode)
            }
        }
        if systemPlaybackEnabled { loadArtwork(for: episode, item: item) }
        let previousHistoryTask = historyTask
        historyTask = Task { [saveHistory] in
            // Serialize writes so quickly selecting episodes preserves their history order.
            await previousHistoryTask?.value
            do {
                try await saveHistory(episode)
            } catch {
                self.errorMessage = "Unable to save listening history: \(error.localizedDescription)"
            }
        }
        updateRemoteAvailability()
        if autoplay { play() }
    }

    private func itemStatusChanged(_ status: AVPlayerItem.Status, item: AVPlayerItem, episode: Episode) {
        if status == .readyToPlay {
            duration = Self.validTime(item.duration.seconds)
            if duration > 0 { defaults.set(duration, forKey: Self.durationKey(for: episode.streamUrl)) }
            // Restore only when loading a new item, never on ordinary play/pause.
            let saved = Self.validTime(defaults.double(forKey: episode.streamUrl))
            seek(to: duration > 0 && saved >= duration ? 0 : saved)
        } else if status == .failed {
            pause()
            errorMessage = item.error?.localizedDescription ?? "This episode could not be played."
        }
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
                if let session { Task { _ = await session.becomeActiveIfPossible() } }
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
        lastListeningTick = nil
        isPlaying = false
        isBuffering = false
        player.pause()
        saveProgress()
    }

    func togglePlayback() { isPlaying ? pause() : play() }

    /// Sets the playback speed for this and future episodes. Unsupported rates are ignored.
    func setPlaybackRate(_ rate: Float) {
        guard Self.playbackRates.contains(rate) else { return }
        playbackRate = rate
        defaults.set(rate, forKey: Self.playbackRateKey)
        player.defaultRate = rate
        if isPlaying { player.rate = rate }
    }

    /// Steps to the next speed, wrapping from the fastest back to 1×.
    func cyclePlaybackRate() {
        let index = Self.playbackRates.firstIndex(of: playbackRate) ?? 0
        setPlaybackRate(Self.playbackRates[(index + 1) % Self.playbackRates.count])
    }

    func seek(to seconds: Double) {
        guard episode != nil, seconds.isFinite else { return }
        let target = max(0, duration > 0 ? min(seconds, duration) : seconds)
        currentTime = target
        lastListeningTick = nil
        isSeeking = true
        seekGeneration += 1
        let generation = seekGeneration
        saveProgress()
        Task {
            _ = await player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero,
                                  toleranceAfter: .zero)
            // A later seek or load owns isSeeking now.
            guard seekGeneration == generation else { return }
            isSeeking = false
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
        itemStatusObservation = nil
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

    /// Counts real (wall-clock) time between playback ticks as listening, so 30 minutes at 2× counts
    /// as 15. Buffering, seeking and pauses reset the tick, and long gaps are ignored.
    func noteListeningTick(at now: Date = Date()) {
        guard isPlaying, !isBuffering, !isSeeking else {
            lastListeningTick = nil
            return
        }
        if let last = lastListeningTick {
            let elapsed = now.timeIntervalSince(last)
            if elapsed > 0 && elapsed < 5 {
                listeningStats.record(elapsed, at: now)
                listeningStatsRevision += 1
            }
        }
        lastListeningTick = now
    }

    /// Fraction of an episode played (0...1), or nil if its length has never been loaded.
    func progress(for streamUrl: String) -> Double? {
        let isCurrent = streamUrl == episode?.streamUrl
        let total = isCurrent && duration > 0 ? duration : defaults.double(forKey: Self.durationKey(for: streamUrl))
        guard total > 0 else { return nil }
        let position = isCurrent ? currentTime : Self.validTime(defaults.double(forKey: streamUrl))
        return min(max(position / total, 0), 1)
    }

    private static func durationKey(for streamUrl: String) -> String {
        "duration:" + streamUrl
    }

    static func validTime(_ seconds: Double) -> Double {
        seconds.isFinite ? max(0, seconds) : 0
    }

    private func observePlayer() {
        // With no queue, AVFoundation calls the observer on the main queue, which is the main actor.
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600),
                                                       queue: nil) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, self.episode != nil, !self.isSeeking,
                      self.player.currentItem?.status == .readyToPlay else { return }
                self.currentTime = Self.validTime(time.seconds)
                self.duration = Self.validTime(self.player.currentItem?.duration.seconds ?? 0)
                self.saveProgress()
                self.noteListeningTick()
            }
        }
        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor in
                guard let self else { return }
                self.isBuffering = self.isPlaying && status == .waitingToPlayAtSpecifiedRate
            }
        }
        notificationTasks.append(Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: AVPlayerItem.didPlayToEndTimeNotification) {
                guard let self else { return }
                guard let item = notification.object as? AVPlayerItem, item === self.player.currentItem else { continue }
                // Keep the position at the end so the episode reads as fully played;
                // load() and play() restart from zero when the saved position reaches the duration.
                if self.duration > 0 { self.currentTime = self.duration }
                self.pause()
            }
        })
    }

    private func observeAudioSession() {
        notificationTasks.append(Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification) {
                guard let self else { return }
                guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: raw) else { continue }
                if type == .began {
                    self.resumeAfterInterruption = self.isPlaying
                    self.pause()
                } else {
                    let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                    let shouldResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
                    if self.resumeAfterInterruption && shouldResume { self.play() }
                    self.resumeAfterInterruption = false
                }
            }
        })
        notificationTasks.append(Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: AVAudioSession.routeChangeNotification) {
                guard let self else { return }
                let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue { self.pause() }
            }
        })
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

    private func register(_ command: MPRemoteCommand, action: @escaping @MainActor (PlaybackManager) -> Void) {
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

    private static func nowPlayingInfo(for episode: Episode) -> [String: Any] {
        [MPMediaItemPropertyTitle: episode.title,
         MPMediaItemPropertyArtist: episode.author,
         MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue]
    }

    private func loadArtwork(for episode: Episode, item: AVPlayerItem) {
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
