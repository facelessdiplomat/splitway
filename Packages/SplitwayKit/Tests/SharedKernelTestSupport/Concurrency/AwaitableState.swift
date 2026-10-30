import Synchronization

public final class AwaitableState<State: Sendable>: Sendable {
    private struct Waiter: Sendable {
        let isSatisfied: @Sendable (State) -> Bool
        let continuation: CheckedContinuation<Void, Never>
    }

    private struct Storage: Sendable {
        var state: State
        var waiters: [Waiter] = []
    }

    private let storage: Mutex<Storage>

    public init(_ initialState: State) {
        storage = Mutex(Storage(state: initialState))
    }

    public var current: State {
        storage.withLock { storage in storage.state }
    }

    @discardableResult
    public func update<Outcome: Sendable>(_ change: (inout State) -> Outcome) -> Outcome {
        let (outcome, readyContinuations) = storage.withLock { storage in
            let outcome = change(&storage.state)
            let state = storage.state
            let ready = storage.waiters.filter { waiter in waiter.isSatisfied(state) }
            storage.waiters.removeAll { waiter in waiter.isSatisfied(state) }
            return (outcome, ready.map(\.continuation))
        }
        for continuation in readyContinuations {
            continuation.resume()
        }
        return outcome
    }

    public func wait(until isSatisfied: @escaping @Sendable (State) -> Bool) async {
        await withCheckedContinuation { continuation in
            let isAlreadySatisfied = storage.withLock { storage in
                guard !isSatisfied(storage.state) else { return true }
                storage.waiters.append(Waiter(isSatisfied: isSatisfied, continuation: continuation))
                return false
            }
            if isAlreadySatisfied {
                continuation.resume()
            }
        }
    }
}
