import TunnelEngine

public enum PacketTunnelError: Error, Equatable, Sendable {
    case configurationUnavailable
    case invalidNetworkPlan(TunnelNetworkPlanError)
    case serviceCatalogUnavailable
    case routingModeChangeNeedsRestart
    case endpointUnresolvable
    case networkSettingsRejected
    case tunnelInterfaceUnavailable
    case engineFailed(TunnelEngineError)
    case cancelled
    case notRunning
}
