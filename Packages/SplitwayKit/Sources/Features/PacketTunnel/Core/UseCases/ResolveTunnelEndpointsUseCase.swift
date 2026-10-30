import TunnelConfiguration
import TunnelEngine

public struct ResolveTunnelEndpointsUseCase: Sendable {
    private let resolver: any EndpointResolver

    public init(resolver: any EndpointResolver) {
        self.resolver = resolver
    }

    public func allEndpoints(
        of configuration: TunnelConfiguration
    ) async throws(EndpointResolutionError) -> [PublicKey: ResolvedEndpoint] {
        var resolved: [PublicKey: ResolvedEndpoint] = [:]
        for peer in configuration.peers {
            guard let endpoint = peer.endpoint else { continue }
            resolved[peer.publicKey] = try await resolver.resolve(endpoint)
        }
        return resolved
    }

    public func reachableEndpoints(of configuration: TunnelConfiguration) async -> [PublicKey: ResolvedEndpoint] {
        var resolved: [PublicKey: ResolvedEndpoint] = [:]
        for peer in configuration.peers {
            guard let endpoint = peer.endpoint else { continue }
            resolved[peer.publicKey] = try? await resolver.resolve(endpoint)
        }
        return resolved
    }
}
