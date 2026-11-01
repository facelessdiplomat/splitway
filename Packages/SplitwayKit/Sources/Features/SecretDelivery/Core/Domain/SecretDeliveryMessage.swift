import TunnelLibrary

public enum SecretDeliveryMessage: Sendable, Equatable {
    case store(tunnel: TunnelIdentifier, configurationText: String)
    case remove(tunnel: TunnelIdentifier)
    case removeAll
}
