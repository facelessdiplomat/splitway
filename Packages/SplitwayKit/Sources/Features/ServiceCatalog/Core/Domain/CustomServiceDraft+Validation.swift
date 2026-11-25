import Foundation
import SharedKernel

extension CustomServiceDraft {
    public var problems: [CustomServiceError] {
        let entries = ParsedEntries(self)
        let nameProblems: [CustomServiceError] = hasName ? [] : [.emptyName]
        let ruleProblems =
            entries.invalidDomains.map(CustomServiceError.invalidDomain)
            + entries.invalidNetworks.map(CustomServiceError.invalidNetwork)
        guard ruleProblems.isEmpty, entries.domains.isEmpty, entries.networks.isEmpty else {
            return nameProblems + ruleProblems
        }
        return nameProblems + [.noRules]
    }

    func rules() throws(CustomServiceError) -> ServiceRules {
        let entries = ParsedEntries(self)
        if let invalidDomain = entries.invalidDomains.first {
            throw .invalidDomain(invalidDomain)
        }
        if let invalidNetwork = entries.invalidNetworks.first {
            throw .invalidNetwork(invalidNetwork)
        }
        do {
            return try ServiceRules(domainSuffixes: entries.domains, networks: entries.networks)
        } catch {
            throw .noRules
        }
    }

    private var hasName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct ParsedEntries {
    private(set) var domains: [DomainName] = []
    private(set) var networks: [IPNetwork] = []
    private(set) var invalidDomains: [String] = []
    private(set) var invalidNetworks: [String] = []

    init(_ draft: CustomServiceDraft) {
        for text in Self.entries(draft.domains) {
            if let domain = try? DomainName(text) {
                domains.append(domain)
            } else {
                invalidDomains.append(text)
            }
        }
        for text in Self.entries(draft.networks) {
            if let network = try? IPNetwork(text) {
                networks.append(network)
            } else {
                invalidNetworks.append(text)
            }
        }
    }

    private static func entries(_ texts: [String]) -> [String] {
        texts
            .map { text in text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { text in !text.isEmpty }
    }
}
