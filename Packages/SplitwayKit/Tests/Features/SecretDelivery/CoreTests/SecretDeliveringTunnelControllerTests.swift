import SecretDelivery
import SecretDeliveryTestSupport
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary
import TunnelLibraryTestSupport

@Suite
struct SecretDeliveringTunnelControllerTests {
    @Test
    func deliversTheSecretBeforeInstallingTheTunnel() async throws {
        let tunnel = try Self.tunnel()
        let extensionStore = InMemoryTunnelSecretStore()
        let systemController = FakeSystemTunnelController()
        let controller = Self.controller(
            wrapping: systemController,
            local: InMemoryTunnelSecretStore(texts: [tunnel.id: "configuration"]),
            channel: LoopbackExtensionSecretChannel(extensionStore: extensionStore)
        )

        try await controller.install(tunnel)

        #expect(await extensionStore.texts[tunnel.id] == "configuration")
        #expect(await systemController.operations == [.install(tunnel.id)])
    }

    @Test
    func doesNotInstallATunnelWhenTheExtensionIsUnreachable() async throws {
        let tunnel = try Self.tunnel()
        let systemController = FakeSystemTunnelController()
        let controller = Self.controller(
            wrapping: systemController,
            local: InMemoryTunnelSecretStore(texts: [tunnel.id: "configuration"]),
            channel: LoopbackExtensionSecretChannel(extensionStore: InMemoryTunnelSecretStore(), isReachable: false)
        )

        await #expect(throws: ConnectionFailure.extensionUnavailable) {
            try await controller.install(tunnel)
        }
        #expect(await systemController.operations.isEmpty)
    }

    @Test
    func reportsAMissingLocalCopyAsAnUnavailableConfiguration() async throws {
        let tunnel = try Self.tunnel()
        let controller = Self.controller(
            wrapping: FakeSystemTunnelController(),
            local: InMemoryTunnelSecretStore(),
            channel: LoopbackExtensionSecretChannel(extensionStore: InMemoryTunnelSecretStore())
        )

        await #expect(throws: ConnectionFailure.configurationUnavailable) {
            try await controller.install(tunnel)
        }
    }

    @Test
    func passesEveryOtherRequestToTheSystemController() async throws {
        let installed = TunnelIdentifier()
        let systemController = FakeSystemTunnelController(installed: installed, status: .reasserting)
        let controller = Self.controller(
            wrapping: systemController,
            local: InMemoryTunnelSecretStore(),
            channel: LoopbackExtensionSecretChannel(extensionStore: InMemoryTunnelSecretStore())
        )

        let reportedTunnel = await controller.installedTunnel()
        let reportedStatus = await controller.currentStatus()
        try await controller.start()
        await controller.stop()

        #expect(reportedTunnel == installed)
        #expect(reportedStatus == .reasserting)
        #expect(await systemController.operations == [.start, .stop])
    }

    private static func controller(
        wrapping systemController: FakeSystemTunnelController,
        local: InMemoryTunnelSecretStore,
        channel: LoopbackExtensionSecretChannel
    ) -> SecretDeliveringTunnelController {
        SecretDeliveringTunnelController(
            controller: systemController,
            deliverSecret: DeliverTunnelSecretUseCase(secrets: local, channel: channel)
        )
    }

    private static func tunnel() throws -> Tunnel {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        return Tunnel(name: try TunnelName("Office"), configuration: configuration)
    }
}
