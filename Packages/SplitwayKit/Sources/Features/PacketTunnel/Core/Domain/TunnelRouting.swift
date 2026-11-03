import AppRouting

public struct TunnelRouting: Sendable, Hashable {
    public let mode: RoutingModeKind
    public let networkPlan: TunnelNetworkPlan
}
