import ApplicationCatalog

public struct ApplicationPickerRow: Sendable, Hashable, Identifiable {
    public let application: InstalledApplication
    public let isSelected: Bool
    public let isResolving: Bool
    public let remarks: [ApplicationRemark]

    public var id: String {
        application.path
    }
}
