import AppRouting
import TunnelConfiguration
import TunnelEngine

public struct TransparentProxyRuntime: Sendable {
    public let network: any RunningUserspaceNetwork
    public let configuration: TunnelConfiguration
    public let plan: TransparentProxyNetworkPlan
    public let decider: FlowRoutingDecider
    public let names: HostnameResolutionPolicy
    public let carriesIPv6: Bool
}
