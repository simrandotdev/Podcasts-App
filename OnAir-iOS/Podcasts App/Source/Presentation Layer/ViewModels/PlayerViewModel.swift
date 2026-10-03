import Foundation
import Combine

/// Playback state and controls for every view that shows or starts playback: the player, the mini
/// player, and episode rows (progress and ON AIR). Wraps the app's `PlaybackManager`.
@MainActor
final class PlayerViewModel: ObservableObject {
    static let playbackRates = PlaybackManager.playbackRates

    @Published private(set) var episode: EpisodeViewModel?
    @Published private(set) var queue: [EpisodeViewModel] = []

    private let playback: PlaybackManager
    private var subscription: AnyCancellable?

    /// - Parameter playback: Defaults to the app's shared player.
    init(playback: PlaybackManager? = nil) {
        let playback = playback ?? .shared
        self.playback = playback
        playback.$episode.map { $0.map(EpisodeViewModel.init(episode:)) }.assign(to: &$episode)
        playback.$queue.map { $0.map(EpisodeViewModel.init(episode:)) }.assign(to: &$queue)
        // Republish every change (position, buffering, rate…) so views observing this update too.
        subscription = playback.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - State

    var isPlaying: Bool { playback.isPlaying }
    var isBuffering: Bool { playback.isBuffering }
    var currentTime: Double { playback.currentTime }
    var duration: Double { playback.duration }
    var playbackRate: Float { playback.playbackRate }
    var canPlayPrevious: Bool { playback.canPlayPrevious }
    var canPlayNext: Bool { playback.canPlayNext }

    var errorMessage: String? {
        get { playback.errorMessage }
        set { playback.errorMessage = newValue }
    }

    /// The episode after the current one in the queue.
    var upNext: EpisodeViewModel? {
        guard let index = playback.currentIndex, index + 1 < playback.queue.count else { return nil }
        return EpisodeViewModel(episode: playback.queue[index + 1])
    }

    // MARK: - Controls

    /// Plays `episode` with `queue` as what comes next. An episode that's already loaded resumes where
    /// it is instead of reloading.
    func play(_ episode: EpisodeViewModel, queue: [EpisodeViewModel]) {
        if playback.episode?.streamUrl == episode.streamUrl {
            playback.play()
        } else {
            playback.load(Episode(episodeViewModel: episode), queue: queue.map(Episode.init(episodeViewModel:)))
        }
    }

    func play() { playback.play() }
    func pause() { playback.pause() }
    func togglePlayback() { playback.togglePlayback() }
    func seek(to seconds: Double) { playback.seek(to: seconds) }
    func skip(by seconds: Double) { playback.skip(by: seconds) }
    func next() { playback.next() }
    func previous() { playback.previous() }
    func close() { playback.close() }
    func setPlaybackRate(_ rate: Float) { playback.setPlaybackRate(rate) }
    func saveProgress() { playback.saveProgress() }

    // MARK: - Episodes and podcasts

    /// Fraction of an episode played (0...1), or nil if its length has never been loaded.
    func progress(for episode: EpisodeViewModel) -> Double? {
        playback.progress(for: episode.streamUrl)
    }

    func isOnAir(_ episode: EpisodeViewModel) -> Bool {
        playback.isPlaying && playback.episode?.streamUrl == episode.streamUrl
    }

    /// Whether one of this podcast's episodes is playing, matched by the podcast's feed URL.
    /// History entries saved before feed URLs were recorded never match.
    func isOnAir(_ podcast: PodcastViewModel) -> Bool {
        guard playback.isPlaying, let feedUrl = playback.episode?.podcastFeedUrl, !feedUrl.isEmpty else { return false }
        return feedUrl == podcast.rssFeedUrl
    }

    /// Like `isOnAir(_:)`, but also matches the podcast's own episodes by stream URL, which covers
    /// history entries saved before feed URLs were recorded.
    func isOnAir(_ podcast: PodcastViewModel, episodes: [EpisodeViewModel]) -> Bool {
        guard playback.isPlaying, let current = playback.episode?.streamUrl else { return false }
        return isOnAir(podcast) || episodes.contains { $0.streamUrl == current }
    }

    static func validTime(_ seconds: Double) -> Double {
        PlaybackManager.validTime(seconds)
    }
}
