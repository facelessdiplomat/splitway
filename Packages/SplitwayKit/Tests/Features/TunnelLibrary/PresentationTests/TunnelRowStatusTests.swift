import DesignSystemPresentation
import Foundation
import Testing
import TunnelConnection
import TunnelLibraryPresentation

@Suite
struct TunnelRowStatusTests {
    private static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_900)
    private static let statusesByConnectionState: [(ConnectionState, TunnelRowStatus)] = [
        (.disconnected, .disconnected),
        (.connecting, .connecting),
        (.connected(since: connectedMoment), .connected(since: connectedMoment)),
        (.reasserting, .reconnecting),
        (.disconnecting, .disconnecting),
        (.failed(.endpointUnresolvable), .failed(.endpointUnresolvable)),
    ]
    private static let tonesByStatus: [(TunnelRowStatus, StatusTone)] = [
        (.disconnected, .neutral),
        (.connecting, .progress),
        (.connected(since: connectedMoment), .positive),
        (.reconnecting, .progress),
        (.disconnecting, .progress),
        (.failed(.endpointUnresolvable), .critical),
        (.unavailable, .warning),
    ]

    @Test(arguments: statusesByConnectionState)
    func turnsEveryConnectionStateIntoARowStatus(state: ConnectionState, status: TunnelRowStatus) {
        #expect(TunnelRowStatus(state) == status)
    }

    @Test(arguments: tonesByStatus)
    func givesEveryRowStatusATone(status: TunnelRowStatus, tone: StatusTone) {
        #expect(status.tone == tone)
    }

    @Test(arguments: [TunnelRowStatus.connecting, .connected(since: connectedMoment), .reconnecting])
    func treatsAStartedSessionAsActive(status: TunnelRowStatus) {
        #expect(status.isActive)
    }

    @Test(arguments: [TunnelRowStatus.disconnected, .disconnecting, .failed(.unknown), .unavailable])
    func treatsEveryOtherStatusAsInactive(status: TunnelRowStatus) {
        #expect(!status.isActive)
    }

    @Test(arguments: [TunnelRowStatus.connected(since: connectedMoment), .reconnecting])
    func expectsStatisticsFromARunningTunnel(status: TunnelRowStatus) {
        #expect(status.reportsStatistics)
    }

    @Test(arguments: [TunnelRowStatus.disconnected, .connecting, .disconnecting, .failed(.unknown), .unavailable])
    func expectsNoStatisticsFromATunnelThatIsNotRunning(status: TunnelRowStatus) {
        #expect(!status.reportsStatistics)
    }

    @Test
    func knowsWhenTheTunnelConnected() {
        #expect(TunnelRowStatus.connected(since: Self.connectedMoment).connectedSince == Self.connectedMoment)
        #expect(TunnelRowStatus.reconnecting.connectedSince == nil)
    }
}
