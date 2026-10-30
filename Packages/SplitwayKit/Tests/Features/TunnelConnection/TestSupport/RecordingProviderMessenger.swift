import ProviderMessaging

public actor RecordingProviderMessenger: ProviderMessenger {
    public private(set) var requests: [ProviderRequest] = []
    private let outcome: Result<ProviderResponse, ProviderMessagingError>

    public init(outcome: Result<ProviderResponse, ProviderMessagingError>) {
        self.outcome = outcome
    }

    public func send(_ request: ProviderRequest) async throws(ProviderMessagingError) -> ProviderResponse {
        requests.append(request)
        return try outcome.get()
    }
}
