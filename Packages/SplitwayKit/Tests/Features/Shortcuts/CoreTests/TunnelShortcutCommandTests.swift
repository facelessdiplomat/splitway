import Foundation
import Shortcuts
import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary

@Suite
struct TunnelShortcutCommandTests {
    private static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_900)

    @Test
    func connectsTheChosenTunnel() async throws {
        let office = try ShortcutTestLibrary.record(named: "Office")
        let library = ShortcutTestLibrary(readable: [office])

        try await library.connect.execute(office.id)

        #expect(await library.controller.operations == [.install(office.id), .start])
    }

    @Test
    func reportsATunnelThatIsNoLongerInTheLibrary() async throws {
        let library = ShortcutTestLibrary(readable: [try ShortcutTestLibrary.record(named: "Office")])

        await #expect(throws: TunnelShortcutError.tunnelNotFound) {
            try await library.connect.execute(TunnelIdentifier())
        }
    }

    @Test
    func reportsATunnelWhoseConfigurationCannotBeRead() async throws {
        let broken = try ShortcutTestLibrary.record(named: "Broken")
        let library = ShortcutTestLibrary(readable: [], unreadable: [broken])

        await #expect(throws: TunnelShortcutError.tunnelUnreadable) {
            try await library.connect.execute(broken.id)
        }
    }

    @Test
    func disconnectsTheChosenTunnelWhenItIsActive() async throws {
        let office = try ShortcutTestLibrary.record(named: "Office")
        let library = ShortcutTestLibrary(
            readable: [office],
            controller: FakeSystemTunnelController(
                installed: office.id,
                status: .connected(since: Self.connectedMoment)
            )
        )

        try await library.disconnect.execute(office.id)

        #expect(await library.controller.operations == [.stop])
    }

    @Test
    func leavesAnotherActiveTunnelConnected() async throws {
        let office = try ShortcutTestLibrary.record(named: "Office")
        let home = try ShortcutTestLibrary.record(named: "Home")
        let library = ShortcutTestLibrary(
            readable: [office, home],
            controller: FakeSystemTunnelController(
                installed: home.id,
                status: .connected(since: Self.connectedMoment)
            )
        )

        try await library.disconnect.execute(office.id)

        #expect(await library.controller.operations.isEmpty)
    }

    @Test
    func togglesAnInactiveTunnelOn() async throws {
        let office = try ShortcutTestLibrary.record(named: "Office")
        let library = ShortcutTestLibrary(readable: [office])

        let outcome = try await library.toggle.execute(office.id)

        #expect(outcome == .connected)
        #expect(await library.controller.operations == [.install(office.id), .start])
    }

    @Test
    func togglesTheActiveTunnelOff() async throws {
        let office = try ShortcutTestLibrary.record(named: "Office")
        let library = ShortcutTestLibrary(
            readable: [office],
            controller: FakeSystemTunnelController(
                installed: office.id,
                status: .connected(since: Self.connectedMoment)
            )
        )

        let outcome = try await library.toggle.execute(office.id)

        #expect(outcome == .disconnected)
        #expect(await library.controller.operations == [.stop])
    }
}
