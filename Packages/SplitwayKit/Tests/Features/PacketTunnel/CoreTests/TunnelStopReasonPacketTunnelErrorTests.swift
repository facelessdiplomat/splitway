import PacketTunnel
import ProviderMessaging
import Testing
import TunnelEngine

@Suite
struct TunnelStopReasonPacketTunnelErrorTests {
    @Test(arguments: [
        (PacketTunnelError.configurationUnavailable, TunnelStopReason.configurationUnavailable),
        (.invalidNetworkPlan(.missingInterfaceAddress(.ipv4)), .configurationUnavailable),
        (.invalidNetworkPlan(.routingModeNotSupported(.selectedApplications)), .unsupportedRoutingMode),
        (.endpointUnresolvable, .endpointUnresolvable),
        (.networkSettingsRejected, .networkSettingsRejected),
        (.tunnelInterfaceUnavailable, .tunnelInterfaceUnavailable),
        (.engineFailed(.tunnelInterfaceUnavailable), .tunnelInterfaceUnavailable),
        (.engineFailed(.configurationRejected), .engineConfigurationRejected),
        (.engineFailed(.socketsUnavailable), .engineSocketsUnavailable),
        (.engineFailed(.internalFailure), .engineFailure),
        (.notRunning, .engineFailure),
    ])
    func tellsTheAppWhyTheTunnelStopped(error: PacketTunnelError, reason: TunnelStopReason) {
        #expect(TunnelStopReason(packetTunnelError: error) == reason)
    }

    @Test
    func reportsNothingForAStartTheSystemCancelled() {
        #expect(TunnelStopReason(packetTunnelError: .cancelled) == nil)
    }
}
