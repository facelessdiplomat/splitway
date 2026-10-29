import Foundation

public protocol ImportFileReader: Sendable {
    func read(_ files: [URL]) async -> ImportFileBatch
}
