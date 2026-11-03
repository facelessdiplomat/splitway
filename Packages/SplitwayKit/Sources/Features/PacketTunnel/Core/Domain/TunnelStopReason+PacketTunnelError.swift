import ProviderMessaging
import TunnelEngine

extension TunnelStopReason {
    public init?(packetTunnelError error: PacketTunnelError) {
        switch error {
        case .configurationUnavailable, .invalidNetworkPlan(.missingInterfaceAddress):
            self = .configurationUnavailable
        case .invalidNetworkPlan(.routingModeNotSupported), .routingModeChangeNeedsRestart:
            self = .unsupportedRoutingMode
        case .endpointUnresolvable:
            self = .endpointUnresolvable
        case .networkSettingsRejected:
            self = .networkSettingsRejected
        case .tunnelInterfaceUnavailable:
            self = .tunnelInterfaceUnavailable
        case .engineFailed(let engineError):
            self.init(engineError: engineError)
        case .notRunning:
            self = .engineFailure
        case .cancelled:
            return nil
        }
    }

    private init(engineError: TunnelEngineError) {
        switch engineError {
        case .tunnelInterfaceUnavailable:
            self = .tunnelInterfaceUnavailable
        case .configurationRejected:
            self = .engineConfigurationRejected
        case .socketsUnavailable:
            self = .engineSocketsUnavailable
        case .deviceNotRunning, .unreadableStatistics, .internalFailure:
            self = .engineFailure
        }
    }
}
