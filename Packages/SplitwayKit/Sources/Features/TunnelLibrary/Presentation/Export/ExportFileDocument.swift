import SwiftUI
import UniformTypeIdentifiers

struct ExportFileDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.data]

    let contents: Data

    init(contents: Data) {
        self.contents = contents
    }

    init(configuration: ReadConfiguration) throws {
        contents = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: contents)
    }
}
