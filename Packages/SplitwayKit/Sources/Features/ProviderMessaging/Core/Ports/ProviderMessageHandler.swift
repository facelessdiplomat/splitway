public protocol ProviderMessageHandler {
    nonisolated(nonsending) func handle(_ request: ProviderRequest) async -> ProviderResponse
}
