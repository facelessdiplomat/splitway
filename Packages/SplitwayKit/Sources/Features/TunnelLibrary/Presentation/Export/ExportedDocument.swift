import Foundation

public struct ExportedDocument: Sendable, Equatable {
    public let fileName: String
    public let contents: Data
    public let kind: ExportedDocumentKind
}
