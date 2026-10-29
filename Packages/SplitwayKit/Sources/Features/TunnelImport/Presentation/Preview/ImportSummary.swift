public struct ImportSummary: Sendable, Equatable {
    public let importedCount: Int
    public let totalCount: Int

    public init(importedCount: Int, totalCount: Int) {
        self.importedCount = importedCount
        self.totalCount = totalCount
    }
}
