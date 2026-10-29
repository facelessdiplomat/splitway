public enum TunnelStorageError: Error, Equatable, Sendable {
    case unavailable
    case corruptedData
    case missingConfiguration
    case unsupportedSchemaVersion
}
