public struct ArchiveImportLimits: Sendable, Hashable {
    public static let standard = ArchiveImportLimits(
        maximumConfigurationFileCount: 100,
        maximumTotalByteCount: 10 * 1024 * 1024
    )

    public let maximumConfigurationFileCount: Int
    public let maximumTotalByteCount: Int

    public init(maximumConfigurationFileCount: Int, maximumTotalByteCount: Int) {
        self.maximumConfigurationFileCount = maximumConfigurationFileCount
        self.maximumTotalByteCount = maximumTotalByteCount
    }
}
