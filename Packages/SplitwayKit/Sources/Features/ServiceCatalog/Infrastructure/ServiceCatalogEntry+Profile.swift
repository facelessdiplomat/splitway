import AppRouting
import ServiceCatalog
import SharedKernel

extension ServiceCatalogEntry {
    func profile() throws(ServiceCatalogError) -> ServiceProfile {
        guard let serviceCategory = ServiceCategory(rawValue: category),
            let ipv4 = Self.networks(ipv4Networks, of: .ipv4),
            let ipv6 = Self.networks(ipv6Networks, of: .ipv6),
            let profile = try? ServiceProfile(
                id: ServiceIdentifier(id),
                displayName: displayName,
                category: serviceCategory,
                icon: ServiceIcon(monogram: monogram, tint: ServiceTint(hexadecimal: tint)),
                rules: ServiceRules(
                    domainSuffixes: domainSuffixes.map { text in try DomainName(text) },
                    networks: ipv4 + ipv6
                ),
                notes: notes
            )
        else { throw .invalidCatalogEntry(id) }
        return profile
    }

    private static func networks(_ texts: [String], of family: IPAddressFamily) -> [IPNetwork]? {
        let networks = texts.compactMap { text in try? IPNetwork(text) }
        guard networks.count == texts.count,
            networks.allSatisfy({ network in network.family == family && !network.hasHostBits })
        else { return nil }
        return networks
    }
}
