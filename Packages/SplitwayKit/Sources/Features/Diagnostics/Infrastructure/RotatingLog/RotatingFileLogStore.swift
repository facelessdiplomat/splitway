import Diagnostics
import Foundation

public struct RotatingFileLogStore: LogStore {
    public static let standardCapacity = 2 * 1024 * 1024

    private static let currentSegmentName = "diagnostics.log"
    private static let previousSegmentName = "diagnostics.previous.log"
    private static let lockFileName = "diagnostics.lock"
    private static let permissions: mode_t = 0o600

    private let currentSegment: URL
    private let previousSegment: URL
    private let lock: LogFileLock
    private let segmentCapacity: Int
    private let coder = LogLineCoder()

    public init(directory: URL, capacity: Int = Self.standardCapacity) {
        currentSegment = directory.appending(path: Self.currentSegmentName)
        previousSegment = directory.appending(path: Self.previousSegmentName)
        lock = LogFileLock(url: directory.appending(path: Self.lockFileName))
        segmentCapacity = capacity / 2
    }

    public func append(_ entry: LogEntry) throws(LogStoreError) {
        let line = try coder.line(for: entry)
        try lock.withLock(.exclusive) { () throws(LogStoreError) in
            if Self.size(of: currentSegment) + line.count > segmentCapacity {
                try Self.replace(previousSegment, with: currentSegment)
            }
            try Self.append(line, to: currentSegment)
        }
    }

    public func entries() throws(LogStoreError) -> [LogEntry] {
        try lock.withLock(.shared) { () throws(LogStoreError) in
            [previousSegment, currentSegment].flatMap { segment in coder.entries(in: Self.contents(of: segment)) }
        }
    }

    public func removeAll() throws(LogStoreError) {
        try lock.withLock(.exclusive) { () throws(LogStoreError) in
            try Self.remove(previousSegment)
            try Self.remove(currentSegment)
        }
    }

    private static func size(of segment: URL) -> Int {
        var status = stat()
        guard stat(segment.path(percentEncoded: false), &status) == 0 else { return 0 }
        return Int(status.st_size)
    }

    private static func contents(of segment: URL) -> Data {
        (try? Data(contentsOf: segment)) ?? Data()
    }

    private static func append(_ line: Data, to segment: URL) throws(LogStoreError) {
        let descriptor = open(
            segment.path(percentEncoded: false), O_WRONLY | O_APPEND | O_CREAT | O_CLOEXEC, permissions)
        guard descriptor >= 0 else { throw .unavailable }
        defer { close(descriptor) }
        let writtenByteCount = line.withUnsafeBytes { bytes in write(descriptor, bytes.baseAddress, bytes.count) }
        guard writtenByteCount == line.count else { throw .unavailable }
    }

    private static func replace(_ destination: URL, with source: URL) throws(LogStoreError) {
        let renamed = rename(source.path(percentEncoded: false), destination.path(percentEncoded: false)) == 0
        guard renamed || errno == ENOENT else { throw .unavailable }
    }

    private static func remove(_ segment: URL) throws(LogStoreError) {
        guard unlink(segment.path(percentEncoded: false)) == 0 || errno == ENOENT else { throw .unavailable }
    }
}
