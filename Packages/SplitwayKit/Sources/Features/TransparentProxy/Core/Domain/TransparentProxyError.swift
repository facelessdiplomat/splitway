import TunnelEngine

public enum TransparentProxyError: Error, Sendable, Equatable {
    case routingModeUnsupported
    case endpointUnresolvable
    case invalidInterface
    case engineFailed(TunnelEngineError)
}
