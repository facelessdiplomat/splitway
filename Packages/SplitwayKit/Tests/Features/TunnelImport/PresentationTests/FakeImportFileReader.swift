import Foundation
import TunnelImport

struct FakeImportFileReader: ImportFileReader {
    let batch: ImportFileBatch

    func read(_ files: [URL]) async -> ImportFileBatch {
        batch
    }
}
