public enum ImportSourceFailureReason: Sendable, Equatable {
    case notText
    case archiveRejected(ArchiveReadingError)
    case noConfigurationsInArchive
}
