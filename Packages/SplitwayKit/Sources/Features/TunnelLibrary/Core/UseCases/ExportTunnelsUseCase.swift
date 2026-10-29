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

    public func exportAll() async throws(TunnelLibraryError) -> ExportedArchive {
        var readableTunnels: [(name: TunnelName, text: String)] = []
        var skippedTunnels: [TunnelName] = []
        for record in try await persistence.records.loadRecords() {
            do {
                readableTunnels.append((record.name, try await persistence.configurationText(for: record.id)))
            } catch .storage(.missingConfiguration), .storage(.corruptedData) {
                skippedTunnels.append(record.name)
            }
        }
        let fileNames = ExportFileNaming.uniqueFileNames(for: readableTunnels.map(\.name))
        let files = zip(readableTunnels, fileNames).map { tunnel, fileName in
            ExportedConfigurationFile(fileName: fileName, contents: tunnel.text)
        }
        do {
            return ExportedArchive(contents: try archiveWriter.archive(files), skippedTunnels: skippedTunnels)
        } catch {
            throw .archiveFailed
        }
    }
}
