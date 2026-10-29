public struct ImportPreview: Sendable, Equatable {
    public let candidates: [ImportPreviewCandidate]
    public let failures: [ImportSourceFailure]
}
