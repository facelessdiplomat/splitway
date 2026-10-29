import TunnelConfiguration
import TunnelImport
import TunnelLibrary

public struct ImportPreviewRow: Identifiable, Sendable, Equatable {
    public let id: Int
    public let source: ImportSource
    public let name: String
    public let importName: String?
    public let isSelected: Bool
    public let isImportable: Bool
    public let hasInvalidName: Bool
    public let errors: [ConfigurationIssue]
    public let warnings: [ConfigurationIssue]
    public let alreadyImportedAs: String?

    public var importsUnderAnotherName: Bool {
        guard let importName else { return false }
        return importName != (try? TunnelName(name))?.description
    }
}
