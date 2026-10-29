import Foundation
import TunnelImport

struct RejectingArchiveReader: ArchiveReader {
    func configurationFiles(in archive: Data) throws(ArchiveReadingError) -> [ArchivedConfigurationFile] {
        throw .unreadableArchive
    }
}
