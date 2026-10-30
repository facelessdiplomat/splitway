import SecretDelivery
import SecretDeliveryTestSupport
import Testing
import TunnelLibrary
import TunnelLibraryTestSupport

@Suite
struct DeliverTunnelSecretUseCaseTests {
    private static let tunnel = TunnelIdentifier()

    @Test
    func sendsTheCurrentLocalCopyBeforeActivation() async throws {
        let (local, extensionStore) = (
            InMemoryTunnelSecretStore(texts: [Self.tunnel: "current"]), InMemoryTunnelSecretStore()
        )
        let useCase = DeliverTunnelSecretUseCase(
            secrets: local, channel: LoopbackExtensionSecretChannel(extensionStore: extensionStore))

        try await useCase.execute(for: Self.tunnel)

        #expect(await extensionStore.texts[Self.tunnel] == "current")
    }

    @Test
    func reportsAnUnreachableExtension() async {
        let channel = LoopbackExtensionSecretChannel(extensionStore: InMemoryTunnelSecretStore(), isReachable: false)
        let useCase = DeliverTunnelSecretUseCase(
            secrets: InMemoryTunnelSecretStore(texts: [Self.tunnel: "current"]), channel: channel)

        await #expect(throws: SecretDeliveryError.extensionUnreachable) {
            try await useCase.execute(for: Self.tunnel)
        }
    }

    @Test
    func reportsATunnelWithoutALocalSecret() async {
        let useCase = DeliverTunnelSecretUseCase(
            secrets: InMemoryTunnelSecretStore(),
            channel: LoopbackExtensionSecretChannel(extensionStore: InMemoryTunnelSecretStore())
        )

        await #expect(throws: SecretDeliveryError.secretUnavailable) {
            try await useCase.execute(for: Self.tunnel)
        }
    }

    @Test
    func reportsAnExtensionThatCouldNotStoreTheSecret() async {
        let extensionStore = InMemoryTunnelSecretStore()
        await extensionStore.failSave(number: 1)
        let useCase = DeliverTunnelSecretUseCase(
            secrets: InMemoryTunnelSecretStore(texts: [Self.tunnel: "current"]),
            channel: LoopbackExtensionSecretChannel(extensionStore: extensionStore)
        )

        await #expect(throws: SecretDeliveryError.rejected(.storageUnavailable)) {
            try await useCase.execute(for: Self.tunnel)
        }
    }
}
