import SharedKernel
import TunnelConfiguration

struct FakeNetworkSelection {
    let ipv4: IPNetwork
    let ipv6: IPNetwork?
    let hasConflict: Bool

    init(configuration: TunnelConfiguration) {
        let occupied = Self.occupiedNetworks(of: configuration)
        let ipv4Choice = Self.choice(preferring: .ipv4BenchmarkingNetwork, avoiding: occupied)
        let carriesIPv6 = configuration.interface.addresses.contains { address in address.family == .ipv6 }
        let ipv6Choice = carriesIPv6 ? Self.choice(preferring: .ipv6BenchmarkingNetwork, avoiding: occupied) : nil
        ipv4 = ipv4Choice.network
        ipv6 = ipv6Choice?.network
        hasConflict = ipv4Choice.hasConflict || ipv6Choice?.hasConflict == true
    }

    var networks: [IPNetwork] {
        [ipv4] + [ipv6].compactMap { network in network }
    }

    private static func occupiedNetworks(of configuration: TunnelConfiguration) -> IPNetworkSet {
        let resolvers = configuration.interface.dns.servers.map { server in IPNetwork(host: server) }
        let endpoints = configuration.peers.compactMap { peer -> IPNetwork? in
            guard case .address(let address) = peer.endpoint?.host else { return nil }
            return IPNetwork(host: address)
        }
        return IPNetworkSet(configuration.interface.addresses + resolvers + endpoints)
    }

    private static func choice(
        preferring preferred: IPNetwork,
        avoiding occupied: IPNetworkSet
    ) -> (network: IPNetwork, hasConflict: Bool) {
        let candidates = [preferred] + preferred.halves
        guard let free = candidates.first(where: { candidate in IPNetworkSet([candidate]).isDisjoint(with: occupied) })
        else {
            return (preferred, true)
        }
        return (free, free != preferred)
    }
}
