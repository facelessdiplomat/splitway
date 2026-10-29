public enum JSONDocumentMigrationError: Error, Equatable, Sendable {
    case malformedDocument
    case newerVersion(Int)
}
