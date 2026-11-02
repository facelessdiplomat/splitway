import Foundation

public protocol AbandonedExportCopies: Sendable {
    func removeCopies(of contents: Data) async
}
