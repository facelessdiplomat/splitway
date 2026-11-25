import PacketTunnel
import ServiceCatalogTestSupport
import SharedKernel
import Testing
import TunnelEngine

@Suite
struct PacketTunnelSessionServiceRoutingTests {
    @Test
    func routesTheSelectedServicesOnceTheDeviceRuns() async throws {
        let telegram = try ServiceCatalogFixtures.profile(id: "telegram", name: "Telegram")
        let environment = try SessionTestEnvironment(services: [telegram])

        try await environment.start(routedBy: SessionTestEnvironment.policy(selecting: [telegram]))

        #expect(
            environment.log.events == [
                .resolved(SessionTestEnvironment.endpoint), .appliedSettings, .locatedInterface,
                .startedDevice(descriptor: 7), .appliedServiceRouting,
            ]
        )
        #expect(environment.device.receivedTranslations.map(\.virtualResolver) == [try IPAddress("198.18.0.2")])
    }

    @Test
    func leavesAFullTunnelWithoutAddressTranslation() async throws {
        let environment = try SessionTestEnvironment()

        try await environment.start()

        #expect(environment.device.receivedTranslations.isEmpty)
    }

    @Test
    func stopsTheDeviceWhenTheEngineRejectsTheServiceRouting() async throws {
        let telegram = try ServiceCatalogFixtures.profile(id: "telegram", name: "Telegram")
        let environment = try SessionTestEnvironment(
            serviceRoutingFailure: .configurationRejected, services: [telegram])

        await #expect(throws: PacketTunnelError.engineFailed(.configurationRejected)) {
            try await environment.start(routedBy: SessionTestEnvironment.policy(selecting: [telegram]))
        }
        #expect(environment.log.events.last == .stoppedDevice)
        #expect(await !environment.session.isRunning)
    }
}
