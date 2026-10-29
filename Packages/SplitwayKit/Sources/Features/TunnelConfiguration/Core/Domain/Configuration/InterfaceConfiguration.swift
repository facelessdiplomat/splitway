import SharedKernel

public struct InterfaceConfiguration: Sendable, Hashable {
    public let privateKey: PrivateKey
    public let addresses: [IPNetwork]
    public let listenPort: NetworkPort?
    public let mtu: MTU?
    public let dns: DNSConfiguration

    public init(
        privateKey: PrivateKey,
        addresses: [IPNetwork] = [],
        listenPort: NetworkPort? = nil,
        mtu: MTU? = nil,
        dns: DNSConfiguration = DNSConfiguration()
    ) {
        self.privateKey = privateKey
        self.addresses = addresses
        self.listenPort = listenPort
        self.mtu = mtu
        self.dns = dns
    }
}
