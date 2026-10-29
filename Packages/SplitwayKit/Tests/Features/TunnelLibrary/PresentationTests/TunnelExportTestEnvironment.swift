import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelLibrary
import TunnelLibraryPresentation
import TunnelLibraryTestSupport

@MainActor
struct TunnelExportTestEnvironment {
    let records = InMemoryTunnelRecordRepository()
    let secrets = InMemoryTunnelSecretStore()
    let model: TunnelExportModel

    init() {
        model = TunnelExportModel(
            exportTunnels: ExportTunnelsUseCase(
                records: records,
                secrets: secrets,
                archiveWriter: ListingArchiveWriter()
            )
        )
    }

    func storeTunnel(named name: String) async throws -> Tunnel {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        return try await CreateTunnelUseCase(records: records, secrets: secrets)
            .execute(name: TunnelName(name), configuration: configuration)
    }
}
