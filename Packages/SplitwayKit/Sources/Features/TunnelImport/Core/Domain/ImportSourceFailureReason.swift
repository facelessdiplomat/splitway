public enum ImportSourceFailureReason: Sendable, Equatable {
    case unreadable
    case notText
    case archiveRejected(ArchiveReadingError)
    case noConfigurationsInArchive
}
