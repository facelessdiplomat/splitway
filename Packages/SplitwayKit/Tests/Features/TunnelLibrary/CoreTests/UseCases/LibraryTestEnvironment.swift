import AppRouting
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelLibrary
import TunnelLibraryTestSupport

struct LibraryTestEnvironment {
    let records = InMemoryTunnelRecordRepository()
    let secrets = InMemoryTunnelSecretStore()

    var createTunnel: CreateTunnelUseCase {
        CreateTunnelUseCase(records: records, secrets: secrets)
    }

    var importTunnels: ImportTunnelsUseCase {
        ImportTunnelsUseCase(records: records, secrets: secrets)
    }

    var updateTunnel: UpdateTunnelUseCase {
        UpdateTunnelUseCase(records: records, secrets: secrets)
    }

    var renameTunnel: RenameTunnelUseCase {
        RenameTunnelUseCase(records: records)
    }

    var duplicateTunnel: DuplicateTunnelUseCase {
        DuplicateTunnelUseCase(records: records, secrets: secrets)
    }

    var reorderTunnels: ReorderTunnelsUseCase {
        ReorderTunnelsUseCase(records: records)
    }

    var loadTunnels: LoadTunnelsUseCase {
        LoadTunnelsUseCase(records: records, secrets: secrets)
    }

    func deleteTunnel(probe: FakeTunnelActivityProbe) -> DeleteTunnelUseCase {
        DeleteTunnelUseCase(records: records, secrets: secrets, activityProbe: probe)
    }

    func exportTunnels(archiveWriter: ListingArchiveWriter = ListingArchiveWriter()) -> ExportTunnelsUseCase {
        ExportTunnelsUseCase(records: records, secrets: secrets, archiveWriter: archiveWriter)
    }

    @discardableResult
    func storedTunnel(named name: String, fixture: String = WgQuickFixtures.minimal) async throws -> Tunnel {
        try await createTunnel.execute(name: TunnelName(name), configuration: configuration(of: fixture))
    }

    func configuration(of fixture: String) throws -> TunnelConfiguration {
        try #require(WgQuickConfigurationParser.parse(fixture).configuration)
    }
}
