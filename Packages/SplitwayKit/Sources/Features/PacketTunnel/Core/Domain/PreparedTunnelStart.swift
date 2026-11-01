import TunnelConfiguration
import TunnelEngine

public struct PreparedTunnelStart: Sendable {
    let routing: TunnelRouting
    let configuration: TunnelConfiguration
    let endpoints: [PublicKey: ResolvedEndpoint]

    public var networkPlan: TunnelNetworkPlan {
        routing.networkPlan
    }
}
