import Foundation
import TunnelLibrary

public struct TemporaryExportCopies: AbandonedExportCopies {
    private static let removalQueue = DispatchQueue(label: "Splitway.ExportCopyRemoval", qos: .utility)
    private static let inspectedKeys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .fileSizeKey]

    private let directory: URL

    public init(directory: URL = FileManager.default.temporaryDirectory) {
        self.directory = directory
    }

    public func removeCopies(of contents: Data) async {
        let directory = directory
        await withCheckedContinuation { continuation in
            Self.removalQueue.async {
                Self.removeCopies(of: contents, in: directory)
                continuation.resume()
            }
        }
    }

    private static func removeCopies(of contents: Data, in directory: URL) {
        for item in items(in: directory) {
            if isDirectory(item) {
                removeCopies(of: contents, inFolder: item)
            } else if isCopy(item, of: contents) {
                try? FileManager.default.removeItem(at: item)
            }
        }
    }

    private static func removeCopies(of contents: Data, inFolder folder: URL) {
        let copies = items(in: folder).filter { file in isCopy(file, of: contents) }
        for copy in copies {
            try? FileManager.default.removeItem(at: copy)
        }
        if !copies.isEmpty, items(in: folder).isEmpty {
            try? FileManager.default.removeItem(at: folder)
        }
    }

    private static func items(in directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: inspectedKeys)) ?? []
    }

    private static func isDirectory(_ item: URL) -> Bool {
        (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    private static func isCopy(_ file: URL, of contents: Data) -> Bool {
        guard let values = try? file.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
            values.isRegularFile == true,
            values.fileSize == contents.count
        else { return false }
        return (try? Data(contentsOf: file)) == contents
    }
}
