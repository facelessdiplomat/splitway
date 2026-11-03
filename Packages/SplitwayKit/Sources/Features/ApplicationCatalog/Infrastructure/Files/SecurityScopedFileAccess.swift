import ApplicationCatalog
import Foundation

public struct SecurityScopedFileAccess: ChosenFileAccess {
    public init() {}

    public func beginAccess(to files: [URL]) -> [URL] {
        files.filter { file in file.startAccessingSecurityScopedResource() }
    }

    public func endAccess(to files: [URL]) {
        for file in files {
            file.stopAccessingSecurityScopedResource()
        }
    }
}
