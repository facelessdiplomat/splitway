import SharedKernel

public struct ServiceRoutingPlan: Sendable, Hashable {
    public let includedRoutes: [IPNetwork]
    public let matchDomains: [DomainName]
    public let virtualResolver: IPAddress
    public let upstreamResolver: IPAddress
    public let fakeIPv4Network: IPNetwork
    public let fakeIPv6Network: IPNetwork?
    public let warnings: [ServiceRoutingWarning]
}
