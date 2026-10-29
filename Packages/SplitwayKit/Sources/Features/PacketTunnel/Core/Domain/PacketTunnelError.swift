import TunnelEngine

public enum PacketTunnelError: Error, Equatable, Sendable {
    case configurationUnavailable
    case invalidNetworkPlan(TunnelNetworkPlanError)
    case endpointUnresolvable
    case networkSettingsRejected
    case tunnelInterfaceUnavailable
    case engineFailed(TunnelEngineError)
    case cancelled
    case notRunning
}
