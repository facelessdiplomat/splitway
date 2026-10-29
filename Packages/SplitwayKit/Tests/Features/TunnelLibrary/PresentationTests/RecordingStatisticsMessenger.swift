import ProviderMessaging

actor RecordingStatisticsMessenger: ProviderMessenger {
    private let outcome: Result<ProviderResponse, ProviderMessagingError>
    private(set) var requestCount = 0
    private var requestWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var isNextResponseHeld = false
    private var heldResponse: CheckedContinuation<Void, Never>?
    private var holdWaiters: [CheckedContinuation<Void, Never>] = []

    init(outcome: Result<ProviderResponse, ProviderMessagingError>) {
        self.outcome = outcome
    }

    func send(_ request: ProviderRequest) async throws(ProviderMessagingError) -> ProviderResponse {
        requestCount += 1
        resumeSatisfiedRequestWaiters()
        if isNextResponseHeld {
            isNextResponseHeld = false
            await withCheckedContinuation { continuation in
                heldResponse = continuation
                for waiter in holdWaiters {
                    waiter.resume()
                }
                holdWaiters.removeAll()
            }
        }
        return try outcome.get()
    }

    func waitForRequests(_ count: Int) async {
        guard requestCount < count else { return }
        await withCheckedContinuation { continuation in requestWaiters.append((count, continuation)) }
    }

    func holdNextResponse() {
        isNextResponseHeld = true
    }

    func waitUntilResponseIsHeld() async {
        guard heldResponse == nil else { return }
        await withCheckedContinuation { continuation in holdWaiters.append(continuation) }
    }

    func releaseHeldResponse() {
        heldResponse?.resume()
        heldResponse = nil
    }

    private func resumeSatisfiedRequestWaiters() {
        let satisfied = requestWaiters.filter { waiter in waiter.count <= requestCount }
        requestWaiters.removeAll { waiter in waiter.count <= requestCount }
        for waiter in satisfied {
            waiter.continuation.resume()
        }
    }
}
