import Foundation
import TunnelImport

struct InMemoryArchiveReader: ArchiveReader {
    private let archives: [Data: Result<[ArchivedConfigurationFile], ArchiveReadingError>]

    init(archives: [Data: Result<[ArchivedConfigurationFile], ArchiveReadingError>] = [:]) {
        self.archives = archives
    }

    func configurationFiles(in archive: Data) throws(ArchiveReadingError) -> [ArchivedConfigurationFile] {
        guard let stored = archives[archive] else { throw .unreadableArchive }
        return try stored.get()
    }
}
