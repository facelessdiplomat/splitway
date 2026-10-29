import AppRouting
import SharedKernel
import TunnelConfiguration

public enum TunnelNetworkPlanner {
    public static func plan(
        for configuration: TunnelConfiguration,
        routedBy policy: RoutingPolicy
    ) throws(TunnelNetworkPlanError) -> TunnelNetworkPlan {
        guard policy.mode.kind == .allTraffic else { throw .routingModeNotSupported(policy.mode.kind) }
        let interface = configuration.interface
        let routes = IPNetworkSet(
            interface.addresses.map(\.normalized) + configuration.peers.flatMap(\.allowedIPs.networks)
        )
        return TunnelNetworkPlan(
            ipv4: try ipv4Plan(addresses: interface.addresses, routes: routes),
            ipv6: ipv6Plan(addresses: interface.addresses, routes: routes),
            dns: dnsPlan(for: interface.dns),
            mtu: interface.mtu.map(TunnelMTU.fixed) ?? .pathMTUWithOverhead(bytes: TunnelMTU.wireGuardOverheadBytes)
        )
    }

    private static func ipv4Plan(
        addresses: [IPNetwork],
        routes: IPNetworkSet
    ) throws(TunnelNetworkPlanError) -> TunnelAddressFamilyPlan? {
        let ipv4Routes = routes.networks.filter { network in network.family == .ipv4 }
        guard !ipv4Routes.isEmpty else { return nil }
        let ipv4Addresses = addresses.filter { address in address.family == .ipv4 }
        guard !ipv4Addresses.isEmpty else { throw .missingInterfaceAddress(.ipv4) }
        return TunnelAddressFamilyPlan(addresses: ipv4Addresses, includedRoutes: ipv4Routes)
    }

    private static func ipv6Plan(addresses: [IPNetwork], routes: IPNetworkSet) -> TunnelAddressFamilyPlan? {
        let ipv6Routes = IPv6LeakProtection.applying(to: routes).networks.filter { network in network.family == .ipv6 }
        guard !ipv6Routes.isEmpty else { return nil }
        let ipv6Addresses = addresses.filter { address in address.family == .ipv6 }
        return TunnelAddressFamilyPlan(
            addresses: ipv6Addresses.isEmpty ? [IPv6LeakProtection.placeholderInterfaceAddress] : ipv6Addresses,
            includedRoutes: ipv6Routes
        )
    }

    private static func dnsPlan(for dns: DNSConfiguration) -> TunnelDNSPlan? {
        guard !dns.servers.isEmpty else { return nil }
        return TunnelDNSPlan(servers: dns.servers, searchDomains: dns.searchDomains, scope: .allDomains)
    }
}
