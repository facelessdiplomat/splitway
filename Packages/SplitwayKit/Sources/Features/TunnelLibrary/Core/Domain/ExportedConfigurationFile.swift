public struct ExportedConfigurationFile: Sendable, Hashable {
    public let fileName: String
    public let contents: String

    public init(fileName: String, contents: String) {
        self.fileName = fileName
        self.contents = contents
    }
}
