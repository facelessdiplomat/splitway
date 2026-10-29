import NetworkExtension

final class TransparentProxyProvider: NETransparentProxyProvider {
    override nonisolated(nonsending) func startProxy(options: [String: Any]? = nil) async throws {
        throw ProviderStartFailure.tunnelEngineNotIntegrated
    }

    override func stopProxy(with reason: NEProviderStopReason) async {}

    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        false
    }
}
