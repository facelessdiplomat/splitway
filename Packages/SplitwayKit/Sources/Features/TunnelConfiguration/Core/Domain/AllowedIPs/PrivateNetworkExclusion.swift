import SharedKernel

public enum PrivateNetworkExclusion {
    private static let ipv4HostPrefixLength = 32

    public static let excludedNetworks = IPNetworkSet(
        (IPNetwork.privateNetworks + IPNetwork.multicastNetworks + IPNetwork.reservedNetworks)
            .filter { network in network.family == .ipv4 }
    )

    public static let publicIPv4Networks = IPNetworkSet([IPNetwork.ipv4DefaultRoute])
        .subtracting(excludedNetworks)
        .networks

    private static let publicIPv4NetworkSet = Set(publicIPv4Networks)

    public static func isApplicable(to allowedIPs: AllowedIPs) -> Bool {
        allowedIPs.networks.contains(.ipv4DefaultRoute) || isApplied(to: allowedIPs)
    }

    public static func isApplied(to allowedIPs: AllowedIPs) -> Bool {
        !allowedIPs.networks.contains(.ipv4DefaultRoute) && publicIPv4NetworkSet.isSubset(of: allowedIPs.networks)
    }

    public static func applying(to allowedIPs: AllowedIPs, keepingReachable dnsServers: [IPAddress]) -> AllowedIPs {
        guard allowedIPs.networks.contains(.ipv4DefaultRoute) else { return allowedIPs }
        let expanded = allowedIPs.networks.flatMap { network in
            network == .ipv4DefaultRoute ? publicIPv4Networks : [network]
        }
        let expandedCoverage = IPNetworkSet(expanded)
        let missingDNSRoutes = hostRoutes(forExcluded: dnsServers).filter { route in
            !expandedCoverage.contains(route)
        }
        return AllowedIPs(expanded + missingDNSRoutes)
    }

    public static func removing(from allowedIPs: AllowedIPs, dnsServers: [IPAddress]) -> AllowedIPs {
        guard isApplied(to: allowedIPs) else { return allowedIPs }
        let addedRoutes = publicIPv4NetworkSet.union(hostRoutes(forExcluded: dnsServers))
        let networks = allowedIPs.networks
        let firstAddedIndex = networks.firstIndex { network in addedRoutes.contains(network) } ?? networks.startIndex
        let keptBefore = networks[..<firstAddedIndex].filter { network in !addedRoutes.contains(network) }
        let keptAfter = networks[firstAddedIndex...].filter { network in !addedRoutes.contains(network) }
        return AllowedIPs(keptBefore + [.ipv4DefaultRoute] + keptAfter)
    }

    private static func hostRoutes(forExcluded servers: [IPAddress]) -> [IPNetwork] {
        servers
            .filter { server in server.family == .ipv4 && excludedNetworks.contains(server) }
            .compactMap { server in try? IPNetwork(address: server, prefixLength: ipv4HostPrefixLength) }
    }
}
