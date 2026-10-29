import TunnelConfiguration
import TunnelEngine

public protocol EndpointResolver: Sendable {
    func resolve(_ endpoint: Endpoint) async throws(EndpointResolutionError) -> ResolvedEndpoint
}
