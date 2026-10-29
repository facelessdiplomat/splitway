import Foundation
import Testing

@testable import ProviderMessagingInfrastructure

@Suite
struct PendingProviderReplyTests {
    private struct ExpiredReply: Error {}

    @Test
    func deliversOnlyTheFirstOutcome() async throws {
        let reply = try await withCheckedThrowingContinuation { continuation in
            let pendingReply = PendingProviderReply(continuation)
            pendingReply.resume(with: .success(Data([1])))
            pendingReply.resume(with: .failure(ExpiredReply()))
            pendingReply.resume(with: .success(Data([2])))
        }

        #expect(reply == Data([1]))
    }

    @Test
    func deliversAFailureThatComesFirst() async {
        await #expect(throws: ExpiredReply.self) {
            try await withCheckedThrowingContinuation { continuation in
                let pendingReply = PendingProviderReply(continuation)
                pendingReply.resume(with: .failure(ExpiredReply()))
                pendingReply.resume(with: .success(Data([1])))
            }
        }
    }
}
