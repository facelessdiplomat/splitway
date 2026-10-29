import PacketTunnel
import SharedKernel
import TunnelConfiguration

public struct TransparentProxyNetworkPlan: Sendable, Hashable {
    private static let localDestinations = IPNetworkSet(
        IPNetwork.loopbackNetworks + IPNetwork.linkLocalNetworks + IPNetwork.multicastNetworks
    )

    public let includedNetworks: IPNetworkSet
    public let excludedNetworks: IPNetworkSet

    public init(for configuration: TunnelConfiguration, resolvedEndpointAddresses: [IPAddress]) {
        let allowedNetworks = IPNetworkSet(configuration.peers.flatMap(\.allowedIPs.networks))
        let endpointAddresses = configuration.peers.compactMap(Self.literalEndpointAddress) + resolvedEndpointAddresses
        includedNetworks = IPv6LeakProtection.applying(to: allowedNetworks)
        excludedNetworks = Self.localDestinations.union(IPNetworkSet(endpointAddresses.map(IPNetwork.init(host:))))
    }

    private static func literalEndpointAddress(of peer: PeerConfiguration) -> IPAddress? {
        guard case .address(let address) = peer.endpoint?.host else { return nil }
        return address
    }
}
