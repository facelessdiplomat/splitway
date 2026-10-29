import PacketTunnel
import Synchronization
import TunnelConfiguration
import TunnelEngine

final class FakeEndpointResolver: EndpointResolver {
    let gate = ResolutionGate()
    private let log: SessionEventLog
    private let answers = Mutex<[String: ResolvedEndpoint]>([:])

    init(log: SessionEventLog) {
        self.log = log
    }

    func answer(_ endpoint: String, with resolved: ResolvedEndpoint) {
        answers.withLock { answers in answers[endpoint] = resolved }
    }

    func resolve(_ endpoint: Endpoint) async throws(EndpointResolutionError) -> ResolvedEndpoint {
        await gate.passThrough()
        let endpointText = endpoint.description
        guard let resolved = answers.withLock({ answers in answers[endpointText] }) else { throw .unresolvable }
        log.record(.resolved(endpointText))
        return resolved
    }
}
