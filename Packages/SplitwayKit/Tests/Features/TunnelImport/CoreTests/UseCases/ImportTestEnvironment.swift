import Foundation
import Testing
import TunnelConfiguration
import TunnelImport
import TunnelLibrary
import TunnelLibraryTestSupport

struct ImportTestEnvironment {
    static let fallbackName = "Pasted tunnel"
    static let archiveData = Data([0x50, 0x4B, 0x03, 0x04] + Array("export".utf8))

    let records = InMemoryTunnelRecordRepository()
    let secrets = InMemoryTunnelSecretStore()
    private let archiveReader: InMemoryArchiveReader

    init(archives: [Data: Result<[ArchivedConfigurationFile], ArchiveReadingError>] = [:]) {
        archiveReader = InMemoryArchiveReader(archives: archives)
    }

    var confirmImport: ConfirmImportUseCase {
        ConfirmImportUseCase(records: records, secrets: secrets)
    }

    func prepareImport() throws -> PrepareImportUseCase {
        PrepareImportUseCase(
            records: records,
            secrets: secrets,
            archiveReader: archiveReader,
            fallbackName: try TunnelName(Self.fallbackName)
        )
    }

    func storeTunnel(named name: String, fixture: String) async throws {
        let configuration = try #require(WgQuickConfigurationParser.parse(fixture).configuration)
        _ = try await CreateTunnelUseCase(records: records, secrets: secrets)
            .execute(name: TunnelName(name), configuration: configuration)
    }
}
