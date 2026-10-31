import Synchronization
import TransparentProxy

public final class InMemoryProcessAncestryReader: ProcessAncestryReader {
    private struct State {
        var launchers: [Int32: RunningProcess]
        var identities: [RunningProcess: CodeIdentity]
        var identityReadCount = 0
    }

    private let state: Mutex<State>

    public init(launchers: [Int32: RunningProcess] = [:], identities: [RunningProcess: CodeIdentity] = [:]) {
        state = Mutex(State(launchers: launchers, identities: identities))
    }

    public var identityReadCount: Int {
        state.withLock { state in state.identityReadCount }
    }

    public func launcher(of processIdentifier: Int32) -> RunningProcess? {
        state.withLock { state in state.launchers[processIdentifier] }
    }

    public func codeIdentity(of process: RunningProcess) throws(CodeIdentityReadingError) -> CodeIdentity {
        let identity = state.withLock { state in
            state.identityReadCount += 1
            return state.identities[process]
        }
        guard let identity else { throw .processUnavailable }
        return identity
    }
}
