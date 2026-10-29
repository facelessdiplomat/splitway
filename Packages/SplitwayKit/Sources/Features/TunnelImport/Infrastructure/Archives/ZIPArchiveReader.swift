import Foundation
import TunnelImport
import ZIPFoundation

public struct ZIPArchiveReader: ArchiveReader {
    private let limits: ArchiveImportLimits

    public init(limits: ArchiveImportLimits = .standard) {
        self.limits = limits
    }

    public func configurationFiles(in archiveData: Data) throws(ArchiveReadingError) -> [ArchivedConfigurationFile] {
        let archive = try Self.openArchive(archiveData)
        var budget = ExtractionBudget(byteLimit: limits.maximumTotalByteCount)
        var files: [ArchivedConfigurationFile] = []
        for entry in try configurationEntries(of: archive) {
            let contents = try Self.contents(of: entry, in: archive, spending: &budget)
            files.append(ArchivedConfigurationFile(fileName: ArchiveEntryPath(entry.path).fileName, contents: contents))
        }
        return files
    }

    private func configurationEntries(of archive: Archive) throws(ArchiveReadingError) -> [Entry] {
        var entries: [Entry] = []
        for entry in archive where entry.type == .file && ArchiveEntryPath(entry.path).isConfigurationFile {
            guard entries.count < limits.maximumConfigurationFileCount else {
                throw .tooManyConfigurationFiles(limit: limits.maximumConfigurationFileCount)
            }
            entries.append(entry)
        }
        return entries
    }

    private static func openArchive(_ data: Data) throws(ArchiveReadingError) -> Archive {
        do {
            return try Archive(data: data, accessMode: .read)
        } catch {
            throw .unreadableArchive
        }
    }

    private static func contents(
        of entry: Entry,
        in archive: Archive,
        spending budget: inout ExtractionBudget
    ) throws(ArchiveReadingError) -> Data {
        var contents = Data()
        let checksum: CRC32
        do {
            checksum = try archive.extract(entry) { chunk in
                try budget.spend(chunk.count)
                contents.append(chunk)
            }
        } catch let error as ArchiveReadingError {
            throw error
        } catch {
            throw .unreadableArchive
        }
        guard checksum == entry.checksum else { throw .unreadableArchive }
        return contents
    }
}
