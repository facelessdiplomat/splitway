import Foundation
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelEditor
import TunnelEditorPresentation
import TunnelLibrary
import TunnelLibraryTestSupport

@MainActor
final class TunnelEditorTestEnvironment {
    let records = InMemoryTunnelRecordRepository()
    let secrets = InMemoryTunnelSecretStore()
    let controller: FakeSystemTunnelController
    private(set) var savedTunnels: [Tunnel] = []

    init(controller: FakeSystemTunnelController = FakeSystemTunnelController()) {
        self.controller = controller
    }

    var actions: TunnelEditorActions {
        let coordinator = ConnectionCoordinator(controller: controller)
        return TunnelEditorActions(
            createTunnel: CreateTunnelUseCase(records: records, secrets: secrets),
            updateTunnel: UpdateTunnelUseCase(records: records, secrets: secrets),
            renameTunnel: RenameTunnelUseCase(records: records),
            activityProbe: ConnectionActivityProbe(controller: controller, coordinator: coordinator),
            activateTunnel: ActivateTunnelUseCase(coordinator: coordinator),
            deactivateTunnel: DeactivateTunnelUseCase(coordinator: coordinator)
        )
    }

    func newTunnelEditor() -> TunnelEditorModel {
        TunnelEditorModel(newTunnelNamed: "New tunnel", routingPlatform: .iOS, actions: actions) { [weak self] tunnel in
            self?.savedTunnels.append(tunnel)
        }
    }

    func editor(for tunnel: Tunnel) -> TunnelEditorModel {
        TunnelEditorModel(editing: tunnel, routingPlatform: .iOS, actions: actions) { [weak self] tunnel in
            self?.savedTunnels.append(tunnel)
        }
    }

    func storeTunnel(named name: String) async throws -> Tunnel {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        return try await CreateTunnelUseCase(records: records, secrets: secrets)
            .execute(name: TunnelName(name), configuration: configuration)
    }

    func storedNames() async throws -> [String] {
        try await records.loadRecords().map(\.name.description)
    }
}

extension TunnelEditorTestEnvironment {
    func flow() -> TunnelEditorFlow {
        TunnelEditorFlow(routingPlatform: .iOS, actions: actions) { _ in
        } didSave: { [weak self] tunnel in
            self?.savedTunnels.append(tunnel)
        }
    }
}
