public enum SecretDeliveryCodingError: Error, Sendable, Equatable {
    case malformed
    case unsupportedSchemaVersion
}
