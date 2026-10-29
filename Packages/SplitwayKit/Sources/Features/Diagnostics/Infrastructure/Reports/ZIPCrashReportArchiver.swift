import Diagnostics
import Foundation
import ZIPFoundation

public struct ZIPCrashReportArchiver: CrashReportArchiver {
    private static let ownerOnlyPermissions: UInt16 = 0o600

    public init() {}

    public func archive(_ bundle: CrashReportBundle) throws(CrashReportArchivingError) -> Data {
        do {
            let archive = try Archive(accessMode: .create)
            for file in bundle.files {
                try Self.add(file, to: archive)
            }
            guard let data = archive.data else { throw CrashReportArchivingError.failed }
            return data
        } catch {
            throw .failed
        }
    }

    private static func add(_ file: CrashReportFile, to archive: Archive) throws {
        let contents = file.contents
        try archive.addEntry(
            with: file.name,
            type: .file,
            uncompressedSize: Int64(contents.count),
            permissions: ownerOnlyPermissions,
            compressionMethod: .deflate,
            provider: { position, size in contents.subdata(in: Int(position)..<Int(position) + size) }
        )
    }
}
