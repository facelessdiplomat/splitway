public struct TunnelNetworkPlan: Sendable, Hashable {
    public let ipv4: TunnelAddressFamilyPlan?
    public let ipv6: TunnelAddressFamilyPlan?
    public let dns: TunnelDNSPlan?
    public let mtu: TunnelMTU
}
