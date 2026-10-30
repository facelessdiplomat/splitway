import SharedKernel
import TunnelConfiguration

public struct UserspaceNetworkInterface: Sendable, Hashable {
    public let addresses: [IPAddress]
    public let dnsServers: [IPAddress]
    public let mtu: MTU

    public init(addresses: [IPAddress], dnsServers: [IPAddress], mtu: MTU) {
        self.addresses = addresses
        self.dnsServers = dnsServers
        self.mtu = mtu
    }
}
