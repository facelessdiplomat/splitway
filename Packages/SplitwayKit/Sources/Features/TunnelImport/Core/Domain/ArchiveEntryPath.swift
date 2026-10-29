public struct ArchiveEntryPath: Sendable, Hashable {
    private static let resourceForkFolderName = "__MACOSX"
    private static let hiddenFilePrefix = "."
    private static let configurationFileExtension = ".conf"

    private let components: [String]
    private let endsWithSeparator: Bool

    public init(_ path: String) {
        components = path.split(whereSeparator: Self.isSeparator).map(String.init)
        endsWithSeparator = path.last.map(Self.isSeparator) ?? true
    }

    public var fileName: String {
        components.last ?? ""
    }

    public var isConfigurationFile: Bool {
        !endsWithSeparator
            && !components.contains(Self.resourceForkFolderName)
            && !fileName.hasPrefix(Self.hiddenFilePrefix)
            && fileName.lowercased().hasSuffix(Self.configurationFileExtension)
    }

    private static func isSeparator(_ character: Character) -> Bool {
        character == "/" || character == "\\"
    }
}
