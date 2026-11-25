import AppRouting
import ControlWidgets
import Foundation
import Shortcuts
import TunnelConfigurationTestSupport
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary
import TunnelLibraryTestSupport

struct ControlTestLibrary {
    static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_900)

    let controller: FakeSystemTunnelController
    private let records: any TunnelRecordRepository
    private let secrets: InMemoryTunnelSecretStore
    private let coordinator: ConnectionCoordinator

    init(
        tunnels: [TunnelRecord],
        controller: FakeSystemTunnelController = FakeSystemTunnelController(),
        records: (any TunnelRecordRepository)? = nil
    ) {
        self.records = records ?? InMemoryTunnelRecordRepository(records: tunnels)
        secrets = InMemoryTunnelSecretStore(
            texts: Dictionary(uniqueKeysWithValues: tunnels.map { tunnel in (tunnel.id, WgQuickFixtures.minimal) })
        )
        self.controller = controller
        coordinator = ConnectionCoordinator(controller: controller)
    }

    static func record(named name: String) throws -> TunnelRecord {
        TunnelRecord(id: TunnelIdentifier(), name: try TunnelName(name), routingPolicy: .default)
    }

    var read: ReadTunnelControlUseCase {
        ReadTunnelControlUseCase(readSlotState: ReadSlotStateUseCase(controller: controller), records: records)
    }

    var set: SetTunnelControlUseCase {
        SetTunnelControlUseCase(
            read: read,
            connect: ConnectTunnelShortcutUseCase(
                loadTunnels: LoadTunnelsUseCase(records: records, secrets: secrets),
                activateTunnel: ActivateTunnelUseCase(coordinator: coordinator)
            ),
            disconnect: DisconnectTunnelShortcutUseCase(
                activityProbe: ConnectionActivityProbe(controller: controller, coordinator: coordinator)
            )
        )
    }
}

struct UnreadableTunnelRecordRepository: TunnelRecordRepository {
    func loadRecords() async throws(TunnelStorageError) -> [TunnelRecord] {
        throw .unavailable
    }

    func saveRecords(_ records: [TunnelRecord]) async throws(TunnelStorageError) {
        throw .unavailable
    }
}
