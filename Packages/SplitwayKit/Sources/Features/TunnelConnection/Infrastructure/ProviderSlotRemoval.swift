import NetworkExtension
import TunnelConnection

public struct ProviderSlotRemoval<Kind: ProviderSlotKind>: Sendable {
    private let providerBundleIdentifier: String

    public init(providerBundleIdentifier: String) {
        self.providerBundleIdentifier = providerBundleIdentifier
    }

    public func removeConfigurations() async throws(ConnectionFailure) {
        var hasFailure = false
        for slot in await Kind.savedSlots() where slot.providerBundleIdentifier == providerBundleIdentifier {
            do {
                try await slot.removeFromPreferences()
            } catch {
                hasFailure = true
            }
        }
        if hasFailure {
            throw .systemConfigurationUnavailable
        }
    }
}
