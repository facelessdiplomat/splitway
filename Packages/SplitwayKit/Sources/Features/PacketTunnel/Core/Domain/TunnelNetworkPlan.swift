public struct TunnelNetworkPlan: Sendable, Hashable {
    public let ipv4: TunnelAddressFamilyPlan?
    public let ipv6: TunnelAddressFamilyPlan?
    public let dns: TunnelDNSPlan?
    public let mtu: TunnelMTU

    public init(ipv4: TunnelAddressFamilyPlan?, ipv6: TunnelAddressFamilyPlan?, dns: TunnelDNSPlan?, mtu: TunnelMTU) {
        self.ipv4 = ipv4
        self.ipv6 = ipv6
        self.dns = dns
        self.mtu = mtu
    }
}
