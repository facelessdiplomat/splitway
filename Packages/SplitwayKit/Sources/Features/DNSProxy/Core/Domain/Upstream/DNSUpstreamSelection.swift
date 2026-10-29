import SharedKernel
import TunnelConfiguration

public struct DNSUpstreamSelection: Sendable, Hashable {
    public static let defaultFallbackServer = IPAddress.ipv4(0x0101_0101)

    public let servers: [IPAddress]

    public init?(for configuration: TunnelConfiguration, fallbackServer: IPAddress = defaultFallbackServer) {
        let configuredServers = Self.servers(configuration.interface.dns.servers, carriedBy: configuration)
        let fallbackServers = Self.servers([fallbackServer], carriedBy: configuration)
        guard let chosenServers = [configuredServers, fallbackServers].first(where: { servers in !servers.isEmpty })
        else { return nil }
        servers = chosenServers
    }

    private static func servers(
        _ candidates: [IPAddress],
        carriedBy configuration: TunnelConfiguration
    ) -> [IPAddress] {
        let carriedNetworks = IPNetworkSet(configuration.peers.flatMap(\.allowedIPs.networks))
        let carriedFamilies = Set(configuration.interface.addresses.map(\.family))
        return candidates.filter { candidate in
            carriedFamilies.contains(candidate.family) && carriedNetworks.contains(candidate)
        }
    }
}
