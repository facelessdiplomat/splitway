import AppRouting
import Foundation

public struct ServiceProfile: Sendable, Hashable, Identifiable {
    public let id: ServiceIdentifier
    public let displayName: String
    public let category: ServiceCategory
    public let icon: ServiceIcon
    public let rules: ServiceRules
    public let notes: String

    public init(
        id: ServiceIdentifier,
        displayName: String,
        category: ServiceCategory,
        icon: ServiceIcon,
        rules: ServiceRules,
        notes: String
    ) throws(ServiceProfileError) {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw .emptyName }
        self.init(id: id, validatedName: name, category: category, icon: icon, rules: rules, notes: notes)
    }

    init(
        id: ServiceIdentifier,
        validatedName: String,
        category: ServiceCategory,
        icon: ServiceIcon,
        rules: ServiceRules,
        notes: String
    ) {
        self.id = id
        displayName = validatedName
        self.category = category
        self.icon = icon
        self.rules = rules
        self.notes = notes
    }
}
