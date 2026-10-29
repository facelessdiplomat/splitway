import Foundation

public protocol ArchiveWriter: Sendable {
    func archive(_ files: [ExportedConfigurationFile]) throws(ArchiveWritingError) -> Data
}
