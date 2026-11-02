import ApplicationCatalog
import Foundation
import Synchronization

public final class InMemoryChosenFileAccess: ChosenFileAccess {
    private let open = Mutex<Set<String>>([])

    public init() {}

    public var openPaths: Set<String> {
        open.withLock { paths in paths }
    }

    public func isOpen(_ path: String) -> Bool {
        open.withLock { paths in paths.contains(path) }
    }

    public func beginAccess(to files: [URL]) -> [URL] {
        open.withLock { paths in
            paths.formUnion(files.map { file in file.path(percentEncoded: false) })
        }
        return files
    }

    public func endAccess(to files: [URL]) {
        open.withLock { paths in
            paths.subtract(files.map { file in file.path(percentEncoded: false) })
        }
    }
}
