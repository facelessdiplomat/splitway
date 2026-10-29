import Foundation
import TunnelLibrary

public struct ListingArchiveWriter: ArchiveWriter {
    private let fails: Bool

    public init(fails: Bool = false) {
        self.fails = fails
    }

    public func archive(_ files: [ExportedConfigurationFile]) throws(ArchiveWritingError) -> Data {
        guard !fails else { throw .failed }
        return Data(files.map(\.fileName).joined(separator: "\n").utf8)
    }
}
