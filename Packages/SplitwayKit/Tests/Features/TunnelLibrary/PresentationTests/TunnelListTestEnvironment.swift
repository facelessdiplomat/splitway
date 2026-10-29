import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary
import TunnelLibraryPresentation
import TunnelLibraryTestSupport

@MainActor
struct TunnelListTestEnvironment {
    let records = InMemoryTunnelRecordRepository()
    let secrets = InMemoryTunnelSecretStore()
    let controller: FakeSystemTunnelController
    let model: TunnelListModel

    init(controller: FakeSystemTunnelController = FakeSystemTunnelController()) {
        self.controller = controller
        let coordinator = ConnectionCoordinator(controller: controller)
        model = TunnelListModel(
            library: TunnelLibraryActions(
                loadTunnels: LoadTunnelsUseCase(records: records, secrets: secrets),
                deleteTunnel: DeleteTunnelUseCase(
                    records: records,
                    secrets: secrets,
                    activityProbe: ConnectionActivityProbe(controller: controller, coordinator: coordinator)
                ),
                duplicateTunnel: DuplicateTunnelUseCase(records: records, secrets: secrets),
                reorderTunnels: ReorderTunnelsUseCase(records: records)
            ),
            connection: TunnelConnectionActions(
                activateTunnel: ActivateTunnelUseCase(coordinator: coordinator),
                deactivateTunnel: DeactivateTunnelUseCase(coordinator: coordinator),
                observeConnection: ObserveConnectionStateUseCase(controller: controller)
            )
        )
    }

    @discardableResult
    func storeTunnel(named name: String) async throws -> Tunnel {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        return try await CreateTunnelUseCase(records: records, secrets: secrets)
            .execute(name: TunnelName(name), configuration: configuration)
    }
}
