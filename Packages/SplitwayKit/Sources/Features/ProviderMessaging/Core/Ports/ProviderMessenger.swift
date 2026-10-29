public protocol ProviderMessenger: Sendable {
    func send(_ request: ProviderRequest) async throws(ProviderMessagingError) -> ProviderResponse
}
