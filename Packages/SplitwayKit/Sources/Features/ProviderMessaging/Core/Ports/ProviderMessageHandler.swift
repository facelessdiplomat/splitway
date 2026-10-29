public protocol ProviderMessageHandler: Sendable {
    func handle(_ request: ProviderRequest) async -> ProviderResponse
}
