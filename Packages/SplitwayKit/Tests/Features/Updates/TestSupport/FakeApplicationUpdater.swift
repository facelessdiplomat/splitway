import Synchronization
import Updates

public final class FakeApplicationUpdater: ApplicationUpdater {
    private let current: Mutex<UpdaterState>
    private let scriptedUpdates: [UpdaterState]
    private let requestedChecks = Mutex(0)

    public init(state: UpdaterState, scriptedUpdates: [UpdaterState] = []) {
        current = Mutex(state)
        self.scriptedUpdates = scriptedUpdates
    }

    public var checkRequests: Int {
        requestedChecks.withLock { count in count }
    }

    public func state() async -> UpdaterState {
        current.withLock { state in state }
    }

    public func stateUpdates() async -> AsyncStream<UpdaterState> {
        let updates = [current.withLock { state in state }] + scriptedUpdates
        return AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }
    }

    public func setChecksAutomatically(_ checksAutomatically: Bool) async {
        current.withLock { state in
            state = UpdaterState(
                checksAutomatically: checksAutomatically,
                canCheckForUpdates: state.canCheckForUpdates
            )
        }
    }

    public func checkForUpdates() async {
        requestedChecks.withLock { count in count += 1 }
    }
}
