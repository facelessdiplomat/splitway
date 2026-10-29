import Synchronization
import TunnelLibraryPresentation

final class ManualTicker: StatisticsTicker {
    private struct State {
        var subscriber: AsyncStream<Void>.Continuation?
        var subscriptionWaiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = Mutex(State())

    var isTicking: Bool {
        state.withLock { state in state.subscriber != nil }
    }

    func ticks() -> AsyncStream<Void> {
        let (ticks, subscriber) = AsyncStream<Void>.makeStream()
        subscriber.onTermination = { [weak self] _ in
            self?.state.withLock { state in state.subscriber = nil }
        }
        let waiters = state.withLock { state in
            state.subscriber = subscriber
            defer { state.subscriptionWaiters.removeAll() }
            return state.subscriptionWaiters
        }
        for waiter in waiters {
            waiter.resume()
        }
        return ticks
    }

    func tick() {
        let subscriber = state.withLock { state in state.subscriber }
        subscriber?.yield()
    }

    func waitUntilTicking() async {
        await withCheckedContinuation { continuation in
            let isTicking = state.withLock { state in
                guard state.subscriber == nil else { return true }
                state.subscriptionWaiters.append(continuation)
                return false
            }
            if isTicking {
                continuation.resume()
            }
        }
    }
}
