public enum SecretDeliveryFailure: String, Error, Codable, Sendable, Equatable {
    case storageUnavailable
    case malformedMessage
    case unsupportedSchemaVersion
}
