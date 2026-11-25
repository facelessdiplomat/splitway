import AppRouting
import Foundation

public struct CustomService: Sendable, Hashable, Identifiable {
    public let id: ServiceIdentifier
    public let name: String
    public let rules: ServiceRules

    public init(id: ServiceIdentifier, name: String, rules: ServiceRules) throws(CustomServiceError) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw .emptyName }
        self.id = id
        self.name = trimmedName
        self.rules = rules
    }

    public var profile: ServiceProfile {
        ServiceProfile(
            id: id,
            validatedName: name,
            category: .custom,
            icon: ServiceIcon(validatedMonogram: String(name.prefix(1)).uppercased(), tint: .neutral),
            rules: rules,
            notes: ""
        )
    }
}
