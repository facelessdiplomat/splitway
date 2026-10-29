import Foundation
import TunnelImport

public struct SecurityScopedFileReader: ImportFileReader {
    private static let readingQueue = DispatchQueue(label: "Splitway.ImportFileReading", qos: .userInitiated)

    public init() {}

    public func read(_ files: [URL]) async -> ImportFileBatch {
        await withCheckedContinuation { continuation in
            Self.readingQueue.async {
                continuation.resume(returning: Self.batch(reading: files))
            }
        }
    }

    private static func batch(reading files: [URL]) -> ImportFileBatch {
        var payloads: [ImportPayload] = []
        var unreadableFileNames: [String] = []
        for file in files {
            if let contents = contents(of: file) {
                payloads.append(.file(name: file.lastPathComponent, contents: contents))
            } else {
                unreadableFileNames.append(file.lastPathComponent)
            }
        }
        return ImportFileBatch(payloads: payloads, unreadableFileNames: unreadableFileNames)
    }

    private static func contents(of file: URL) -> Data? {
        let isAccessingScopedFile = file.startAccessingSecurityScopedResource()
        defer {
            if isAccessingScopedFile {
                file.stopAccessingSecurityScopedResource()
            }
        }
        var contents: Data?
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: file, options: [], error: &coordinationError) { readableFile in
            contents = limitedContents(of: readableFile)
        }
        return contents
    }

    private static func limitedContents(of file: URL) -> Data? {
        guard let byteCount = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize,
            byteCount <= ImportFileBatch.maximumFileByteCount
        else { return nil }
        return try? Data(contentsOf: file)
    }
}
