import Diagnostics
import Foundation

public struct QueuedLogHistory: LogHistory {
    private static let queue = DispatchQueue(label: "Splitway.LogHistory", qos: .utility)

    private let store: any LogStore

    public init(store: any LogStore) {
        self.store = store
    }

    public func entries() async throws(LogStoreError) -> [LogEntry] {
        let store = store
        return try await Self.perform { () throws(LogStoreError) -> [LogEntry] in try store.entries() }
    }

    public func removeAll() async throws(LogStoreError) {
        let store = store
        try await Self.perform { () throws(LogStoreError) in try store.removeAll() }
    }

    private static func perform<Value: Sendable>(
        _ work: @escaping @Sendable () throws(LogStoreError) -> Value
    ) async throws(LogStoreError) -> Value {
        let outcome: Result<Value, LogStoreError> = await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: Result(catching: work))
            }
        }
        return try outcome.get()
    }
}
