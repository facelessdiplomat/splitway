import SharedKernel

public struct ServiceRules: Sendable, Hashable {
    public let domainSuffixes: [DomainName]
    public let networks: [IPNetwork]

    public init(domainSuffixes: [DomainName], networks: [IPNetwork]) throws(ServiceRulesError) {
        guard !domainSuffixes.isEmpty || !networks.isEmpty else { throw .empty }
        self.domainSuffixes = DomainSuffixSet(domainSuffixes).suffixes
        self.networks = IPNetworkSet(networks).networks
    }
}
