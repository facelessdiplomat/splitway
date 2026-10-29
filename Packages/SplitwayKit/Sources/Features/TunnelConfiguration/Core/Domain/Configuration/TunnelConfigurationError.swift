public enum TunnelConfigurationError: Error, Equatable, Sendable {
    case duplicatePeerPublicKey(PublicKey)
}
