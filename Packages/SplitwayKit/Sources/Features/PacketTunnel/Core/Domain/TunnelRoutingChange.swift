public struct TunnelRoutingChange: Sendable {
    let routing: TunnelRouting
    public let changedNetworkPlan: TunnelNetworkPlan?
}
