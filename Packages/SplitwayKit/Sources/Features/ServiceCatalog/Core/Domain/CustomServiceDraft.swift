import AppRouting

public struct CustomServiceDraft: Sendable, Hashable {
    public let identifier: ServiceIdentifier?
    public let name: String
    public let domains: [String]
    public let networks: [String]

    public init(editing identifier: ServiceIdentifier? = nil, name: String, domains: [String], networks: [String]) {
        self.identifier = identifier
        self.name = name
        self.domains = domains
        self.networks = networks
    }

    public init(editing profile: ServiceProfile) {
        self.init(
            editing: profile.id,
            name: profile.displayName,
            domains: profile.rules.domainSuffixes.map(\.description),
            networks: profile.rules.networks.map(\.description)
        )
    }
}
