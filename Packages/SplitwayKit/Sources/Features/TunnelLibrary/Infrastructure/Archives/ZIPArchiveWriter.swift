import Foundation
import TunnelLibrary
import ZIPFoundation

public struct ZIPArchiveWriter: ArchiveWriter {
    private static let ownerOnlyPermissions: UInt16 = 0o600

    public init() {}

    public func archive(_ files: [ExportedConfigurationFile]) throws(ArchiveWritingError) -> Data {
        do {
            let archive = try Archive(accessMode: .create)
            for file in files {
                try Self.add(file, to: archive)
            }
            guard let data = archive.data else { throw ArchiveWritingError.failed }
            return data
        } catch {
            throw .failed
        }
    }

    private static func add(_ file: ExportedConfigurationFile, to archive: Archive) throws {
        let contents = Data(file.contents.utf8)
        try archive.addEntry(
            with: file.fileName,
            type: .file,
            uncompressedSize: Int64(contents.count),
            permissions: ownerOnlyPermissions,
            compressionMethod: .deflate,
            provider: { position, size in contents.subdata(in: Int(position)..<Int(position) + size) }
        )
    }
}
