public struct ImportSourceFailure: Sendable, Equatable {
    public let source: ImportSource
    public let reason: ImportSourceFailureReason

    public init(source: ImportSource, reason: ImportSourceFailureReason) {
        self.source = source
        self.reason = reason
    }
}
