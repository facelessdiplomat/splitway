import ControlWidgets
import Foundation
import Testing
import TunnelConnection
import TunnelLibrary

@Suite
struct TunnelControlSnapshotTests {
    private static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_900)

    @Test(arguments: [ConnectionState.connecting, .connected(since: connectedMoment), .reasserting])
    func isOnWhileTheLastTunnelIsActive(connection: ConnectionState) throws {
        let office = try ControlTestLibrary.record(named: "Office")

        let snapshot = TunnelControlSnapshot(
            selection: nil, slot: SlotState(tunnelID: office.id, connection: connection), records: [office])

        #expect(snapshot.targetTunnel == office.id)
        #expect(snapshot.value == TunnelControlValue(isOn: true, tunnelName: "Office"))
    }

    @Test(arguments: [ConnectionState.disconnected, .disconnecting, .failed(.systemConfigurationUnavailable)])
    func isOffWhileTheLastTunnelIsInactive(connection: ConnectionState) throws {
        let office = try ControlTestLibrary.record(named: "Office")

        let snapshot = TunnelControlSnapshot(
            selection: nil, slot: SlotState(tunnelID: office.id, connection: connection), records: [office])

        #expect(snapshot.value == TunnelControlValue(isOn: false, tunnelName: "Office"))
    }

    @Test
    func isOnWhileTheChosenTunnelIsActive() throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let home = try ControlTestLibrary.record(named: "Home")

        let snapshot = TunnelControlSnapshot(
            selection: home.id,
            slot: SlotState(tunnelID: home.id, connection: .connected(since: Self.connectedMoment)),
            records: [office, home]
        )

        #expect(snapshot.value == TunnelControlValue(isOn: true, tunnelName: "Home"))
    }

    @Test
    func staysOffWhileAnotherTunnelIsActive() throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let home = try ControlTestLibrary.record(named: "Home")

        let snapshot = TunnelControlSnapshot(
            selection: home.id,
            slot: SlotState(tunnelID: office.id, connection: .connected(since: Self.connectedMoment)),
            records: [office, home]
        )

        #expect(snapshot.targetTunnel == home.id)
        #expect(snapshot.value == TunnelControlValue(isOn: false, tunnelName: "Home"))
    }

    @Test
    func offersTheFirstTunnelBeforeAnyConnection() throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let home = try ControlTestLibrary.record(named: "Home")

        let snapshot = TunnelControlSnapshot(selection: nil, slot: .empty, records: [office, home])

        #expect(snapshot.targetTunnel == office.id)
        #expect(snapshot.value == TunnelControlValue(isOn: false, tunnelName: "Office"))
    }

    @Test
    func offersTheFirstTunnelWhenTheLastOneWasDeleted() throws {
        let office = try ControlTestLibrary.record(named: "Office")

        let snapshot = TunnelControlSnapshot(
            selection: nil,
            slot: SlotState(tunnelID: TunnelIdentifier(), connection: .disconnected),
            records: [office]
        )

        #expect(snapshot.targetTunnel == office.id)
    }

    @Test
    func keepsAChosenTunnelThatWasDeleted() throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let deleted = TunnelIdentifier()

        let snapshot = TunnelControlSnapshot(
            selection: deleted,
            slot: SlotState(tunnelID: office.id, connection: .disconnected),
            records: [office]
        )

        #expect(snapshot.targetTunnel == deleted)
        #expect(snapshot.value == TunnelControlValue(isOn: false, tunnelName: nil))
    }

    @Test
    func hasNothingToControlWithoutTunnels() {
        let snapshot = TunnelControlSnapshot(selection: nil, slot: .empty, records: [])

        #expect(snapshot.targetTunnel == nil)
        #expect(snapshot.value == TunnelControlValue(isOn: false, tunnelName: nil))
    }
}
