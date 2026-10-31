public struct ImportFileBatch: Sendable, Equatable {
    public static let maximumFileByteCount = 10 * 1024 * 1024
    public static let empty = ImportFileBatch(payloads: [], unreadableFileNames: [])

    public let payloads: [ImportPayload]
    public let unreadableFileNames: [String]

    public init(payloads: [ImportPayload], unreadableFileNames: [String]) {
        self.payloads = payloads
        self.unreadableFileNames = unreadableFileNames
    }

    public func appending(_ other: ImportFileBatch) -> ImportFileBatch {
        ImportFileBatch(
            payloads: payloads + other.payloads,
            unreadableFileNames: unreadableFileNames + other.unreadableFileNames
        )
    }
}
