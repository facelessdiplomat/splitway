import TunnelEngine

public enum ConnectionFailure: Error, Sendable, Hashable {
    case permissionDenied
    case systemConfigurationUnavailable
    case startRejected
    case configurationUnavailable
    case routingModeUnsupported
    case extensionUnavailable
    case networkSettingsRejected
    case endpointUnresolvable
    case engineFailed(TunnelEngineError)
    case unknown
}
