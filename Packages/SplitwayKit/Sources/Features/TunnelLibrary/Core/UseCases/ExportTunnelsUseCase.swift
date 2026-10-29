import Foundation

public struct ExportTunnelsUseCase: Sendable {
    private let persistence: TunnelPersistence
    private let archiveWriter: any ArchiveWriter

    public init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore, archiveWriter: any ArchiveWriter) {
        persistence = TunnelPersistence(records: records, secrets: secrets)
        self.archiveWriter = archiveWriter
    }

    public func exportConfiguration(of id: TunnelIdentifier) async throws(TunnelLibraryError)
        -> ExportedConfigurationFile
    {
        let records = try await persistence.records.loadRecords()
        let record = records[try TunnelRecordAccess.index(of: id, in: records)]
        return ExportedConfigurationFile(
            fileName: ExportFileNaming.fileName(for: record.name),
            contents: try await persistence.configurationText(for: id)
        )
    }

    public func exportAll() async throws(TunnelLibraryError) -> Data {
        let records = try await persistence.records.loadRecords()
        let fileNames = ExportFileNaming.uniqueFileNames(for: records.map(\.name))
        var files: [ExportedConfigurationFile] = []
        for (record, fileName) in zip(records, fileNames) {
            files.append(
                ExportedConfigurationFile(
                    fileName: fileName, contents: try await persistence.configurationText(for: record.id))
            )
        }
        do {
            return try archiveWriter.archive(files)
        } catch {
            throw .archiveFailed
        }
    }
}
