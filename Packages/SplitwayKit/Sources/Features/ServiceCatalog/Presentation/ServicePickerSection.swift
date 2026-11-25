import ServiceCatalog

public struct ServicePickerSection: Identifiable, Sendable, Hashable {
    public let category: ServiceCategory
    public let rows: [ServicePickerRow]

    public var id: ServiceCategory {
        category
    }
}
