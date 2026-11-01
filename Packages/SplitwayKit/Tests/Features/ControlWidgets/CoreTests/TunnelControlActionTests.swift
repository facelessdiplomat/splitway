import ControlWidgets
import Shortcuts
import Testing
import TunnelConnectionTestSupport
import TunnelLibrary

@Suite
struct TunnelControlActionTests {
    @Test
    func readsTheStateOfTheLastTunnel() async throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let library = ControlTestLibrary(
            tunnels: [office],
            controller: FakeSystemTunnelController(
                installed: office.id,
                status: .connected(since: ControlTestLibrary.connectedMoment)
            )
        )

        let snapshot = try await library.read.execute(selection: nil)

        #expect(snapshot.value == TunnelControlValue(isOn: true, tunnelName: "Office"))
    }

    @Test
    func reportsALibraryThatCannotBeRead() async {
        let library = ControlTestLibrary(tunnels: [], records: UnreadableTunnelRecordRepository())

        await #expect(throws: TunnelShortcutError.libraryUnavailable) {
            try await library.read.execute(selection: nil)
        }
    }

    @Test
    func connectsTheChosenTunnel() async throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let home = try ControlTestLibrary.record(named: "Home")
        let library = ControlTestLibrary(tunnels: [office, home])

        try await library.set.execute(isOn: true, selection: home.id)

        #expect(await library.controller.operations == [.install(home.id), .start])
    }

    @Test
    func connectsTheLastTunnelWhenNoneIsChosen() async throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let home = try ControlTestLibrary.record(named: "Home")
        let library = ControlTestLibrary(
            tunnels: [office, home],
            controller: FakeSystemTunnelController(installed: home.id, status: .disconnected)
        )

        try await library.set.execute(isOn: true, selection: nil)

        #expect(await library.controller.operations == [.install(home.id), .start])
    }

    @Test
    func connectsTheFirstTunnelBeforeAnyConnection() async throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let home = try ControlTestLibrary.record(named: "Home")
        let library = ControlTestLibrary(tunnels: [office, home])

        try await library.set.execute(isOn: true, selection: nil)

        #expect(await library.controller.operations == [.install(office.id), .start])
    }

    @Test
    func disconnectsTheChosenTunnel() async throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let library = ControlTestLibrary(
            tunnels: [office],
            controller: FakeSystemTunnelController(
                installed: office.id,
                status: .connected(since: ControlTestLibrary.connectedMoment)
            )
        )

        try await library.set.execute(isOn: false, selection: office.id)

        #expect(await library.controller.operations == [.stop])
    }

    @Test
    func disconnectsTheActiveTunnelWhenNoneIsChosen() async throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let home = try ControlTestLibrary.record(named: "Home")
        let library = ControlTestLibrary(
            tunnels: [office, home],
            controller: FakeSystemTunnelController(
                installed: home.id,
                status: .connecting
            )
        )

        try await library.set.execute(isOn: false, selection: nil)

        #expect(await library.controller.operations == [.stop])
    }

    @Test
    func leavesAnotherActiveTunnelConnected() async throws {
        let office = try ControlTestLibrary.record(named: "Office")
        let home = try ControlTestLibrary.record(named: "Home")
        let library = ControlTestLibrary(
            tunnels: [office, home],
            controller: FakeSystemTunnelController(
                installed: home.id,
                status: .connected(since: ControlTestLibrary.connectedMoment)
            )
        )

        try await library.set.execute(isOn: false, selection: office.id)

        #expect(await library.controller.operations.isEmpty)
    }

    @Test
    func reportsThatThereIsNoTunnelToConnect() async {
        let library = ControlTestLibrary(tunnels: [])

        await #expect(throws: TunnelShortcutError.tunnelNotFound) {
            try await library.set.execute(isOn: true, selection: nil)
        }
    }
}
