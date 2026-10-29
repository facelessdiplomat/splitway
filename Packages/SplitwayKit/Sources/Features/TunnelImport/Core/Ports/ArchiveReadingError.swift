public enum ArchiveReadingError: Error, Equatable, Sendable {
    case unreadableArchive
    case tooManyConfigurationFiles(limit: Int)
    case configurationsTooLarge(limitInBytes: Int)
}
