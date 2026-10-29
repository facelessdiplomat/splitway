import Foundation
import Synchronization

final class PendingProviderReply: Sendable {
    private let continuation: Mutex<CheckedContinuation<Data?, any Error>?>

    init(_ continuation: CheckedContinuation<Data?, any Error>) {
        self.continuation = Mutex(continuation)
    }

    func resume(with outcome: Result<Data?, any Error>) {
        let pendingContinuation = continuation.withLock { continuation in
            defer { continuation = nil }
            return continuation
        }
        pendingContinuation?.resume(with: outcome)
    }
}
