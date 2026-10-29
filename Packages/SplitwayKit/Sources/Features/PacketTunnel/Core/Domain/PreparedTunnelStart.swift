import TunnelConfiguration
import TunnelEngine

public struct PreparedTunnelStart: Sendable {
    public let networkPlan: TunnelNetworkPlan
    let configuration: TunnelConfiguration
    let endpoints: [PublicKey: ResolvedEndpoint]
}
