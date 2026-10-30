import Dispatch

enum BlockingCall {
    private static let queue = DispatchQueue(label: "Splitway.Tests.BlockingCalls", attributes: .concurrent)

    static func perform<Value: Sendable, Failure: Error>(
        _ work: @escaping @Sendable () throws(Failure) -> Value
    ) async throws(Failure) -> Value {
        let result: Result<Value, Failure> = await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: Result { () throws(Failure) -> Value in try work() })
            }
        }
        return try result.get()
    }
}
