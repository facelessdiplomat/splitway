import NetworkExtension
import ProviderMessaging
import ProviderMessagingInfrastructure

public actor PacketTunnelSlotMessenger: ProviderMessenger {
    private let providerBundleIdentifier: String
    private var sessionMessenger: TunnelProviderSessionMessenger?

    public init(providerBundleIdentifier: String) {
        self.providerBundleIdentifier = providerBundleIdentifier
    }

    public func send(_ request: ProviderRequest) async throws(ProviderMessagingError) -> ProviderResponse {
        guard let messenger = await slotSessionMessenger() else { throw .extensionUnavailable }
        do {
            return try await messenger.send(request)
        } catch {
            sessionMessenger = nil
            throw error
        }
    }

    private func slotSessionMessenger() async -> TunnelProviderSessionMessenger? {
        if let sessionMessenger {
            return sessionMessenger
        }
        let providerBundleIdentifier = providerBundleIdentifier
        let savedManagers = (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
        let slot = savedManagers.first { manager in manager.providerBundleIdentifier == providerBundleIdentifier }
        guard let session = slot?.connection as? NETunnelProviderSession else { return nil }
        let messenger = TunnelProviderSessionMessenger(session: session)
        sessionMessenger = messenger
        return messenger
    }
}
