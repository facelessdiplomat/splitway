import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary

@Suite
struct ConnectionActivityProbeTests {
    private let office: Tunnel
    private let prague: Tunnel

    init() throws {
        office = try ConnectionTestTunnels.named("Office")
        prague = try ConnectionTestTunnels.named("Prague")
    }

    @Test
    func reportsOnlyTheInstalledRunningTunnelAsActive() async {
        let controller = FakeSystemTunnelController(installed: office.id, status: .connected(since: .distantPast))
        let probe = ConnectionActivityProbe(
            controller: controller, coordinator: ConnectionCoordinator(controller: controller))

        #expect(await probe.isActive(office.id))
        #expect(await !probe.isActive(prague.id))
    }

    @Test
    func stopsTheTunnelWhenItIsActive() async throws {
        let controller = FakeSystemTunnelController(installed: office.id, status: .connecting)
        let probe = ConnectionActivityProbe(
            controller: controller, coordinator: ConnectionCoordinator(controller: controller))

        try await probe.stop(office.id)

        #expect(await controller.operations == [.stop])
    }

    @Test
    func leavesAnInactiveTunnelAlone() async throws {
        let controller = FakeSystemTunnelController(installed: office.id, status: .disconnected)
        let probe = ConnectionActivityProbe(
            controller: controller, coordinator: ConnectionCoordinator(controller: controller))

        try await probe.stop(office.id)

        #expect(await controller.operations.isEmpty)
    }
}
