import Synchronization
import TransparentProxy

public final class InMemoryCodeIdentityReader: CodeIdentityReader {
    private struct State {
        var identities: [ProcessInstance: CodeIdentity]
        var readCount = 0
    }

    private let state: Mutex<State>

    public init(identities: [ProcessInstance: CodeIdentity] = [:]) {
        state = Mutex(State(identities: identities))
    }

    public var readCount: Int {
        state.withLock { state in state.readCount }
    }

    public func codeIdentity(of auditToken: AuditToken) throws(CodeIdentityReadingError) -> CodeIdentity {
        let identity = state.withLock { state in
            state.readCount += 1
            return state.identities[auditToken.processInstance]
        }
        guard let identity else { throw .processUnavailable }
        return identity
    }
}
