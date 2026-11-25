import AppRouting
import ServiceCatalog

public struct ServicePickerRow: Identifiable, Sendable, Hashable {
    public let service: ServiceProfile
    public let isSelected: Bool

    public var id: ServiceIdentifier {
        service.id
    }
}
