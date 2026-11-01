import AppRouting
import Foundation
import Shortcuts
import TunnelConfigurationTestSupport
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary
import TunnelLibraryTestSupport

struct ShortcutTestLibrary {
    let records: InMemoryTunnelRecordRepository
    let secrets: InMemoryTunnelSecretStore
    let controller: FakeSystemTunnelController
    let coordinator: ConnectionCoordinator

    init(
        readable: [TunnelRecord],
        unreadable: [TunnelRecord] = [],
        controller: FakeSystemTunnelController = FakeSystemTunnelController()
    ) {
        records = InMemoryTunnelRecordRepository(records: readable + unreadable)
        secrets = InMemoryTunnelSecretStore(
            texts: Dictionary(uniqueKeysWithValues: readable.map { record in (record.id, WgQuickFixtures.minimal) })
        )
        self.controller = controller
        coordinator = ConnectionCoordinator(controller: controller)
    }

    static func record(named name: String) throws -> TunnelRecord {
        TunnelRecord(id: TunnelIdentifier(), name: try TunnelName(name), routingPolicy: .default)
    }

    var find: FindShortcutTunnelsUseCase {
        FindShortcutTunnelsUseCase(records: records)
    }

    var activityProbe: ConnectionActivityProbe {
        ConnectionActivityProbe(controller: controller, coordinator: coordinator)
    }

    var connect: ConnectTunnelShortcutUseCase {
        ConnectTunnelShortcutUseCase(
            loadTunnels: LoadTunnelsUseCase(records: records, secrets: secrets),
            activateTunnel: ActivateTunnelUseCase(coordinator: coordinator)
        )
    }

    var disconnect: DisconnectTunnelShortcutUseCase {
        DisconnectTunnelShortcutUseCase(activityProbe: activityProbe)
    }

    var toggle: ToggleTunnelShortcutUseCase {
        ToggleTunnelShortcutUseCase(connect: connect, disconnect: disconnect, activityProbe: activityProbe)
    }
}
