public enum TunnelProviderConfigurationError: Error, Equatable, Sendable {
    case missing
    case unsupportedVersion(Int)
    case malformed
    case unencodable
}
