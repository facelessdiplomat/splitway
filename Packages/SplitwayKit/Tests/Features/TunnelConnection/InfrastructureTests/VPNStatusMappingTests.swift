import Foundation
import NetworkExtension
import Testing
import TunnelConnection
import TunnelConnectionInfrastructure

@Suite
struct VPNStatusMappingTests {
    private static let fallbackMoment = Date(timeIntervalSince1970: 1_793_268_900)
    private static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_000)

    @Test(arguments: [
        (NEVPNStatus.invalid, SystemConnectionStatus.notConfigured),
        (.disconnected, .disconnected),
        (.connecting, .connecting),
        (.connected, .connected(since: connectedMoment)),
        (.reasserting, .reasserting),
        (.disconnecting, .disconnecting),
    ])
    func mapsEverySystemStatus(vpnStatus: NEVPNStatus, status: SystemConnectionStatus) {
        let mapped = VPNStatusMapping.status(
            of: vpnStatus,
            connectedDate: Self.connectedMoment,
            fallbackConnectedDate: Self.fallbackMoment
        )

        #expect(mapped == status)
    }

    @Test
    func usesTheFallbackWhenTheSystemKnowsNoConnectionDate() {
        let mapped = VPNStatusMapping.status(
            of: .connected, connectedDate: nil, fallbackConnectedDate: Self.fallbackMoment)

        #expect(mapped == .connected(since: Self.fallbackMoment))
    }
}
