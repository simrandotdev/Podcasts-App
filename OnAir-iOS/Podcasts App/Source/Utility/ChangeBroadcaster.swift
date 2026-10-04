import Foundation
import Synchronization

/// Tells every listener that something changed, each through its own `AsyncStream`.
///
/// An `AsyncStream` has a single consumer, so each call to `changes()` returns a new stream. A stream holds at
/// most one undelivered change: changes that arrive before a listener catches up are delivered as one, which is
/// all a listener that reloads needs.
final class ChangeBroadcaster: Sendable {
    private let continuations = Mutex<[UUID: AsyncStream<Void>.Continuation]>([:])

    /// A stream of every change sent after this call. The listener is registered before this returns, so no
    /// change is missed while the caller starts iterating.
    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        continuations.withLock { $0[id] = continuation }
        // Iteration ends when the listener's task is cancelled; forget the listener then.
        continuation.onTermination = { [weak self] _ in
            self?.continuations.withLock { $0[id] = nil }
        }
        return stream
    }

    func send() {
        let listeners = continuations.withLock { Array($0.values) }
        for listener in listeners {
            listener.yield()
        }
    }
}
