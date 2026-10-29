import SharedKernel
import Synchronization

public final class ManualTicker: Ticker {
    private struct State {
        var subscriber: AsyncStream<Void>.Continuation?
        var subscriptionWaiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = Mutex(State())

    public init() {}

    public var isTicking: Bool {
        state.withLock { state in state.subscriber != nil }
    }

    public func ticks() -> AsyncStream<Void> {
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

    public func tick() {
        let subscriber = state.withLock { state in state.subscriber }
        subscriber?.yield()
    }

    public func waitUntilTicking() async {
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
