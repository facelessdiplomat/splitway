import Synchronization
import SystemExtension

public final class ControlledSystemExtensionActivator: SystemExtensionActivator {
    private struct State {
        var continuation: AsyncStream<SystemExtensionActivationEvent>.Continuation?
        var requestCount = 0
        var requestWaiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = Mutex(State())

    public init() {}

    public var requestCount: Int {
        state.withLock { state in state.requestCount }
    }

    public func requestActivation() -> AsyncStream<SystemExtensionActivationEvent> {
        let (events, continuation) = AsyncStream.makeStream(of: SystemExtensionActivationEvent.self)
        let waiters = state.withLock { state in
            state.requestCount += 1
            state.continuation = continuation
            defer { state.requestWaiters.removeAll() }
            return state.requestWaiters
        }
        for waiter in waiters {
            waiter.resume()
        }
        return events
    }

    public func waitUntilRequested() async {
        await withCheckedContinuation { waiter in
            let isRequested = state.withLock { state in
                guard state.continuation == nil else { return true }
                state.requestWaiters.append(waiter)
                return false
            }
            if isRequested {
                waiter.resume()
            }
        }
    }

    public func send(_ event: SystemExtensionActivationEvent) {
        state.withLock { state in state.continuation }?.yield(event)
    }

    public func finish() {
        state.withLock { state in state.continuation }?.finish()
    }
}
