import SharedKernel

public struct ServiceRoutingTranslation: Sendable, Hashable {
    public let virtualResolver: IPAddress
    public let upstreamResolver: IPAddress
    public let fakeIPv4Network: IPNetwork
    public let fakeIPv6Network: IPNetwork?

    public init(
        virtualResolver: IPAddress,
        upstreamResolver: IPAddress,
        fakeIPv4Network: IPNetwork,
        fakeIPv6Network: IPNetwork?
    ) {
        self.virtualResolver = virtualResolver
        self.upstreamResolver = upstreamResolver
        self.fakeIPv4Network = fakeIPv4Network
        self.fakeIPv6Network = fakeIPv6Network
    }
}
