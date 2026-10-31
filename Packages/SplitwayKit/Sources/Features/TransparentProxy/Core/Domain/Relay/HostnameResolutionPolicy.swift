import SharedKernel

public struct HostnameResolutionPolicy: Sendable {
    private static let multicastDNSTopLevelLabel = "local"

    private let tunnelNetworks: IPNetworkSet
    private let resolvesNamesThroughTunnel: Bool

    public init(tunnelNetworks: IPNetworkSet, resolvesNamesThroughTunnel: Bool) {
        self.tunnelNetworks = tunnelNetworks
        self.resolvesNamesThroughTunnel = resolvesNamesThroughTunnel
    }

    public func target(forHostname hostname: String?, address: IPAddress) -> RelayTarget {
        guard resolvesNamesThroughTunnel, let hostname, !Self.isMulticastDNSName(hostname),
            let name = try? DomainName(hostname)
        else { return .address(address) }
        return .hostname(name)
    }

    public func address(choosingFrom resolvedAddresses: [IPAddress], insteadOf address: IPAddress) -> IPAddress {
        guard !resolvedAddresses.contains(address) else { return address }
        return resolvedAddresses.first { resolved in
            resolved.family == address.family && tunnelNetworks.contains(resolved)
        } ?? address
    }

    private static func isMulticastDNSName(_ hostname: String) -> Bool {
        hostname.split(separator: ".").last?.lowercased() == multicastDNSTopLevelLabel
    }
}
