import SharedKernel

public struct DomainSuffixSet: Sendable, Hashable {
    public let suffixes: [DomainName]

    public init(_ domains: some Sequence<DomainName>) {
        let uniqueDomains = Set(domains)
        let names = Set(uniqueDomains.map(\.description))
        suffixes = uniqueDomains
            .filter { domain in !Self.hasListedParent(of: domain.description, in: names) }
            .sorted { first, second in first.description < second.description }
    }

    public func contains(_ domain: DomainName) -> Bool {
        suffixes.contains { suffix in domain.isSameOrSubdomain(of: suffix) }
    }

    private static func hasListedParent(of name: String, in names: Set<String>) -> Bool {
        var parent = Substring(name)
        while let separator = parent.firstIndex(of: ".") {
            parent = parent[parent.index(after: separator)...]
            if names.contains(String(parent)) {
                return true
            }
        }
        return false
    }
}
