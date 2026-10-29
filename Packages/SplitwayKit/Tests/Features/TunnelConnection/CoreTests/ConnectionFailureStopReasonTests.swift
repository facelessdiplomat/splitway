import ProviderMessaging
import Testing
import TunnelConnection
import TunnelEngine

@Suite
struct ConnectionFailureStopReasonTests {
    @Test(arguments: [
        (TunnelStopReason.configurationUnavailable, ConnectionFailure.configurationUnavailable),
        (.unsupportedRoutingMode, .routingModeUnsupported),
        (.endpointUnresolvable, .endpointUnresolvable),
        (.networkSettingsRejected, .networkSettingsRejected),
        (.tunnelInterfaceUnavailable, .engineFailed(.tunnelInterfaceUnavailable)),
        (.engineConfigurationRejected, .engineFailed(.configurationRejected)),
        (.engineSocketsUnavailable, .engineFailed(.socketsUnavailable)),
        (.engineFailure, .engineFailed(.internalFailure)),
    ])
    func explainsEveryReasonTheTunnelStoppedFor(reason: TunnelStopReason, failure: ConnectionFailure) {
        #expect(ConnectionFailure(stopReason: reason) == failure)
    }
}
