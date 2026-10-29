public enum ProviderMessagingError: Error, Equatable, Sendable {
    case extensionUnavailable
    case noResponse
    case incompatibleExtension(protocolVersion: Int)
    case malformedResponse
}
