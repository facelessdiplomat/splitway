public enum ProviderMessageCodingError: Error, Equatable, Sendable {
    case unsupportedProtocolVersion(found: Int)
    case malformedMessage
    case unencodableMessage
}
