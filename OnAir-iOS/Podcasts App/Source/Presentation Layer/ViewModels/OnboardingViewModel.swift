import Foundation
import Observation

/// Backs the welcome tour (`OnboardingView`): whether it's showing, and turning on New Episode Alerts from
/// its last page. The tour shows once, on the first launch after the app is installed. Settings can show it
/// again.
@MainActor
@Observable
final class OnboardingViewModel {
    static let completedKey = "hasCompletedOnboarding"

    /// Whether the welcome tour is showing.
    private(set) var isPresented: Bool
    /// Whether New Episode Alerts are on, so the tour can say so.
    var alertsEnabled: Bool { newEpisodesManager.notificationsEnabled }

    private let defaults: UserDefaults
    private let newEpisodesManager: NewEpisodesManager

    /// - Parameter newEpisodesManager: Defaults to the app's shared new-episodes manager.
    init(defaults: UserDefaults = .standard, newEpisodesManager: NewEpisodesManager? = nil) {
        self.defaults = defaults
        self.newEpisodesManager = newEpisodesManager ?? .shared
        isPresented = !defaults.bool(forKey: Self.completedKey)
    }

    /// The user finished or skipped the tour. It doesn't show again on its own.
    func finish() {
        defaults.set(true, forKey: Self.completedKey)
        isPresented = false
    }

    /// Shows the tour again, from Settings.
    func showAgain() {
        isPresented = true
    }

    /// Asks for permission to send notifications, and turns on New Episode Alerts if it's given.
    /// Returns whether alerts are on.
    @discardableResult
    func turnOnAlerts() async -> Bool {
        await newEpisodesManager.setNotificationsEnabled(true)
    }
}
