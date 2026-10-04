import XCTest
@testable import Podcasts_Bin

@MainActor
final class ChangeBroadcasterTests: XCTestCase {
    func test_send_reachesEveryListener() async {
        let sut = ChangeBroadcaster()
        let first = ChangeCounter(sut.changes())
        let second = ChangeCounter(sut.changes())

        sut.send()

        let delivered = await waitUntil { first.count == 1 && second.count == 1 }
        XCTAssertTrue(delivered)
    }

    func test_listener_receivesOnlyChangesSentAfterItSubscribed() async {
        let sut = ChangeBroadcaster()
        sut.send()
        let late = ChangeCounter(sut.changes())

        sut.send()

        let delivered = await waitUntil { late.count == 1 }
        XCTAssertTrue(delivered)
        let extra = await waitUntil(timeout: 0.2) { late.count > 1 }
        XCTAssertFalse(extra)
    }

    func test_changesBeforeTheListenerCatchesUp_arriveAsOne() async {
        let sut = ChangeBroadcaster()
        let counter = ChangeCounter(sut.changes())

        // The counter runs on the main actor too, so it can't read until the test awaits.
        sut.send()
        sut.send()
        sut.send()

        let delivered = await waitUntil { counter.count == 1 }
        XCTAssertTrue(delivered)
        let extra = await waitUntil(timeout: 0.2) { counter.count > 1 }
        XCTAssertFalse(extra)
    }
}
