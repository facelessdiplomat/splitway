import TunnelEngine

public enum ConnectionFailure: Error, Sendable, Hashable {
    case permissionDenied
    case systemConfigurationUnavailable
    case startRejected
    case configurationUnavailable
    case endpointUnresolvable
    case engineFailed(TunnelEngineError)
    case unknown
}
