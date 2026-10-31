import Foundation
import TunnelImport

struct NamedImportFileReader: ImportFileReader {
    let contentsByName: [String: String]

    func read(_ files: [URL]) async -> ImportFileBatch {
        ImportFileBatch(
            payloads: files.compactMap { file in
                contentsByName[file.lastPathComponent].map { contents in
                    .file(name: file.lastPathComponent, contents: Data(contents.utf8))
                }
            },
            unreadableFileNames: files.map(\.lastPathComponent).filter { name in contentsByName[name] == nil }
        )
    }
}
