import SwiftUI
import UniformTypeIdentifiers

public struct ExportedDataDocument: FileDocument {
    public static let readableContentTypes: [UTType] = [.data]

    public let contents: Data

    public init(contents: Data) {
        self.contents = contents
    }

    public init(configuration: ReadConfiguration) throws {
        contents = configuration.file.regularFileContents ?? Data()
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: contents)
    }
}
