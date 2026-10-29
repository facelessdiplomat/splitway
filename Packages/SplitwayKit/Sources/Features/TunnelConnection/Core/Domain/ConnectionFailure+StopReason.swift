import ProviderMessaging

extension ConnectionFailure {
    public init(stopReason: TunnelStopReason) {
        switch stopReason {
        case .configurationUnavailable: self = .configurationUnavailable
        case .unsupportedRoutingMode: self = .routingModeUnsupported
        case .endpointUnresolvable: self = .endpointUnresolvable
        case .networkSettingsRejected: self = .networkSettingsRejected
        case .tunnelInterfaceUnavailable: self = .engineFailed(.tunnelInterfaceUnavailable)
        case .engineConfigurationRejected: self = .engineFailed(.configurationRejected)
        case .engineSocketsUnavailable: self = .engineFailed(.socketsUnavailable)
        case .engineFailure: self = .engineFailed(.internalFailure)
        }
    }
}
