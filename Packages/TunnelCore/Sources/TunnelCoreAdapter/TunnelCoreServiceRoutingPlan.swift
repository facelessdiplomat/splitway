public struct TunnelCoreServiceRoutingPlan: Sendable, Hashable {
    public let virtualDNS: String
    public let fakeNetwork: String
    public let upstreamDNS: String

    public init(virtualDNS: String, fakeNetwork: String, upstreamDNS: String) {
        self.virtualDNS = virtualDNS
        self.fakeNetwork = fakeNetwork
        self.upstreamDNS = upstreamDNS
    }
}
