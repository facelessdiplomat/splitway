import ProviderMessaging

public struct SlotSelectingMessenger: ProviderMessenger {
    private let selection: SlotSelectingTunnelController
    private let packetTunnel: any ProviderMessenger
    private let transparentProxy: any ProviderMessenger

    public init(
        selection: SlotSelectingTunnelController,
        packetTunnel: any ProviderMessenger,
        transparentProxy: any ProviderMessenger
    ) {
        self.selection = selection
        self.packetTunnel = packetTunnel
        self.transparentProxy = transparentProxy
    }

    public func send(_ request: ProviderRequest) async throws(ProviderMessagingError) -> ProviderResponse {
        let messenger = await selection.routesThroughTransparentProxy() ? transparentProxy : packetTunnel
        return try await messenger.send(request)
    }
}
