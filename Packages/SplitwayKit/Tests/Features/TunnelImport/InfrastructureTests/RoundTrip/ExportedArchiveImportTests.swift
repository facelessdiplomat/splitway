import Foundation
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelImport
import TunnelImportInfrastructure
import TunnelLibrary
import TunnelLibraryInfrastructure
import TunnelLibraryTestSupport

@Suite
struct ExportedArchiveImportTests {
    @Test
    func importsAnExportedArchiveWithoutLosingAnything() async throws {
        let exportingRecords = InMemoryTunnelRecordRepository()
        let exportingSecrets = InMemoryTunnelSecretStore()
        let create = CreateTunnelUseCase(records: exportingRecords, secrets: exportingSecrets)
        let office = try await create.execute(
            name: TunnelName("Office"),
            configuration: try configuration(WgQuickFixtures.full)
        )
        let lab = try await create.execute(
            name: TunnelName("Lab/Prague"),
            configuration: try configuration(WgQuickFixtures.multiplePeers)
        )
        let archive = try await ExportTunnelsUseCase(
            records: exportingRecords,
            secrets: exportingSecrets,
            archiveWriter: ZIPArchiveWriter()
        ).exportAll()

        let preview = try await PrepareImportUseCase(
            records: InMemoryTunnelRecordRepository(),
            secrets: InMemoryTunnelSecretStore(),
            archiveReader: ZIPArchiveReader(),
            fallbackName: .untitled
        ).execute([.file(name: "Splitway Tunnels.zip", contents: archive.contents)])

        #expect(preview.candidates.map(\.configuration) == [office.configuration, lab.configuration])
        #expect(preview.candidates.map(\.proposedName.description) == ["Office", "Lab-Prague"])
        #expect(preview.failures.isEmpty)
    }

    private func configuration(_ text: String) throws -> TunnelConfiguration {
        try #require(WgQuickConfigurationParser.parse(text).configuration)
    }
}
