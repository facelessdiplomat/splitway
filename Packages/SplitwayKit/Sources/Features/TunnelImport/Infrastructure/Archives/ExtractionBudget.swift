import TunnelImport

struct ExtractionBudget {
    private let byteLimit: Int
    private var spentByteCount = 0

    init(byteLimit: Int) {
        self.byteLimit = byteLimit
    }

    mutating func spend(_ byteCount: Int) throws(ArchiveReadingError) {
        spentByteCount += byteCount
        guard spentByteCount <= byteLimit else { throw .configurationsTooLarge(limitInBytes: byteLimit) }
    }
}
