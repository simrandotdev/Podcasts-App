import XCTest
@testable import Podcasts_Bin

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    /// Temporary defaults and files, removed after the test.
    private func makeManagers() -> IsolatedManagers {
        let managers = IsolatedManagers()
        addTeardownBlock { await managers.tearDown() }
        return managers
    }

    func test_firstLaunch_showsTheTour() {
        let managers = makeManagers()

        XCTAssertTrue(OnboardingViewModel(defaults: managers.defaults).isPresented)
    }

    func test_finish_hidesTheTourOnLaterLaunches() {
        let managers = makeManagers()
        let sut = OnboardingViewModel(defaults: managers.defaults)

        sut.finish()

        XCTAssertFalse(sut.isPresented)
        XCTAssertFalse(OnboardingViewModel(defaults: managers.defaults).isPresented)
    }

    func test_showAgain_showsTheTourAfterItWasFinished() {
        let managers = makeManagers()
        let sut = OnboardingViewModel(defaults: managers.defaults)
        sut.finish()

        sut.showAgain()

        XCTAssertTrue(sut.isPresented)
    }

    func test_turnOnAlerts_whenAllowed_turnsAlertsOn() async {
        let managers = makeManagers()
        let newEpisodes = NewEpisodesManager(stateURL: managers.directory.appendingPathComponent("NewEpisodes.json"),
                                             defaults: managers.defaults, loadFavorites: { [] },
                                             fetchEpisodes: { _ in [] }, notifier: AllowingNotifier())
        let sut = OnboardingViewModel(defaults: managers.defaults, newEpisodesManager: newEpisodes)

        let isOn = await sut.turnOnAlerts()

        XCTAssertTrue(isOn)
        XCTAssertTrue(sut.alertsEnabled)
    }

    func test_turnOnAlerts_whenDenied_leavesAlertsOff() async {
        let managers = makeManagers()
        // IsolatedManagers' notifier refuses permission.
        let sut = OnboardingViewModel(defaults: managers.defaults, newEpisodesManager: managers.newEpisodesManager())

        let isOn = await sut.turnOnAlerts()

        XCTAssertFalse(isOn)
        XCTAssertFalse(sut.alertsEnabled)
    }
}

/// Grants notification permission without asking.
private struct AllowingNotifier: NewEpisodeNotifying {
    func requestAuthorization() async -> Bool { true }
    func isAuthorized() async -> Bool { true }
    func notify(_ episodes: [FreshEpisode]) async {}
}
