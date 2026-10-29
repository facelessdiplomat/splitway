import Foundation

public protocol ArchiveReader: Sendable {
    func configurationFiles(in archive: Data) throws(ArchiveReadingError) -> [ArchivedConfigurationFile]
}
