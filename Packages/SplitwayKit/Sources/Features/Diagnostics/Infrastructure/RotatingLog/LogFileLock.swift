import Diagnostics
import Foundation

struct LogFileLock: Sendable {
    enum Mode {
        case shared
        case exclusive

        var operation: Int32 {
            switch self {
            case .shared: LOCK_SH
            case .exclusive: LOCK_EX
            }
        }
    }

    private static let permissions: mode_t = 0o600

    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func withLock<Result>(
        _ mode: Mode,
        _ body: () throws(LogStoreError) -> Result
    ) throws(LogStoreError) -> Result {
        let descriptor = try openLockFile()
        defer { close(descriptor) }
        try acquire(mode, on: descriptor)
        defer { flock(descriptor, LOCK_UN) }
        return try body()
    }

    private func openLockFile() throws(LogStoreError) -> Int32 {
        let path = url.path(percentEncoded: false)
        var descriptor = open(path, O_RDWR | O_CREAT | O_CLOEXEC, Self.permissions)
        if descriptor < 0, errno == ENOENT {
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            descriptor = open(path, O_RDWR | O_CREAT | O_CLOEXEC, Self.permissions)
        }
        guard descriptor >= 0 else { throw .unavailable }
        return descriptor
    }

    private func acquire(_ mode: Mode, on descriptor: Int32) throws(LogStoreError) {
        while flock(descriptor, mode.operation) != 0 {
            guard errno == EINTR else { throw .unavailable }
        }
    }
}
