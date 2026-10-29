public struct ImportFileBatch: Sendable, Equatable {
    public static let maximumFileByteCount = 10 * 1024 * 1024

    public let payloads: [ImportPayload]
    public let unreadableFileNames: [String]

    public init(payloads: [ImportPayload], unreadableFileNames: [String]) {
        self.payloads = payloads
        self.unreadableFileNames = unreadableFileNames
    }
}
