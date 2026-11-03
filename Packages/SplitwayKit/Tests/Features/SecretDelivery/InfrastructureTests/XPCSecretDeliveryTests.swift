import Foundation
import SecretDelivery
import SecretDeliveryInfrastructure
import Testing
import TunnelLibrary
import TunnelLibraryTestSupport

@Suite
struct XPCSecretDeliveryTests {
    private let tunnel = TunnelIdentifier()

    @Test
    func storesTheSecretInTheStoreOfTheExtension() async throws {
        let extensionStore = InMemoryTunnelSecretStore()
        let listener = SecretDeliveryListener.anonymous(store: extensionStore)
        listener.start()

        try await Self.channel(to: listener).deliver(.store(tunnel: tunnel, configurationText: "configuration"))

        #expect(await extensionStore.texts[tunnel] == "configuration")
    }

    @Test
    func removesTheSecretFromTheStoreOfTheExtension() async throws {
        let extensionStore = InMemoryTunnelSecretStore(texts: [tunnel: "configuration"])
        let listener = SecretDeliveryListener.anonymous(store: extensionStore)
        listener.start()

        try await Self.channel(to: listener).deliver(.remove(tunnel: tunnel))

        #expect(await extensionStore.texts[tunnel] == nil)
    }

    @Test
    func reportsThatTheExtensionCouldNotStoreTheSecret() async {
        let extensionStore = InMemoryTunnelSecretStore()
        await extensionStore.failSave(number: 1)
        let listener = SecretDeliveryListener.anonymous(store: extensionStore)
        listener.start()
        let channel = Self.channel(to: listener)

        await #expect(throws: SecretDeliveryError.rejected(.storageUnavailable)) {
            try await channel.deliver(.store(tunnel: tunnel, configurationText: "configuration"))
        }
    }

    @Test
    func treatsAClientRejectedByTheRequirementAsAnUnreachableExtension() async throws {
        let otherApplication = try ClientCodeRequirement(
            teamIdentifier: "ABCDE12345",
            bundleIdentifier: "com.example.other"
        )
        let extensionStore = InMemoryTunnelSecretStore()
        let listener = SecretDeliveryListener.anonymous(store: extensionStore, clientRequirement: otherApplication)
        listener.start()
        let channel = Self.channel(to: listener)

        await #expect(throws: SecretDeliveryError.extensionUnreachable) {
            try await channel.deliver(.store(tunnel: tunnel, configurationText: "configuration"))
        }
        #expect(await extensionStore.texts.isEmpty)
    }

    private static func channel(to listener: SecretDeliveryListener) -> XPCExtensionSecretChannel {
        let endpoint = listener.endpoint
        return XPCExtensionSecretChannel { NSXPCConnection(listenerEndpoint: endpoint) }
    }
}
