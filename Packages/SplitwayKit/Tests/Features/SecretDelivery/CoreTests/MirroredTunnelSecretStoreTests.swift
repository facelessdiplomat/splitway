import AppRouting
import SecretDelivery
import SecretDeliveryTestSupport
import SharedKernelTestSupport
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelLibrary
import TunnelLibraryTestSupport

@Suite
struct MirroredTunnelSecretStoreTests {
    private static let tunnel = TunnelIdentifier()

    @Test
    func savesTheSecretLocallyAndInTheExtension() async throws {
        let (local, extensionStore) = (InMemoryTunnelSecretStore(), InMemoryTunnelSecretStore())
        let store = Self.store(local: local, channel: LoopbackExtensionSecretChannel(extensionStore: extensionStore))

        try await store.saveConfigurationText("first", for: Self.tunnel)

        #expect(await local.texts[Self.tunnel] == "first")
        #expect(await extensionStore.texts[Self.tunnel] == "first")
    }

    @Test
    func keepsTheLocalSaveAndReportsWhenTheExtensionIsUnreachable() async throws {
        let (local, failures) = (InMemoryTunnelSecretStore(), AwaitableState<[SecretDeliveryError]>([]))
        let channel = LoopbackExtensionSecretChannel(extensionStore: InMemoryTunnelSecretStore(), isReachable: false)
        let store = Self.store(local: local, channel: channel, failures: failures)

        try await store.saveConfigurationText("first", for: Self.tunnel)

        #expect(await local.texts[Self.tunnel] == "first")
        #expect(failures.current == [.extensionUnreachable])
    }

    @Test
    func deletesTheSecretLocallyAndInTheExtension() async throws {
        let local = InMemoryTunnelSecretStore(texts: [Self.tunnel: "first"])
        let extensionStore = InMemoryTunnelSecretStore(texts: [Self.tunnel: "first"])
        let store = Self.store(local: local, channel: LoopbackExtensionSecretChannel(extensionStore: extensionStore))

        try await store.deleteConfigurationText(for: Self.tunnel)

        #expect(await local.texts[Self.tunnel] == nil)
        #expect(await extensionStore.texts[Self.tunnel] == nil)
    }

    @Test
    func readsOnlyTheLocalCopy() async throws {
        let local = InMemoryTunnelSecretStore(texts: [Self.tunnel: "local"])
        let extensionStore = InMemoryTunnelSecretStore(texts: [Self.tunnel: "extension"])
        let channel = LoopbackExtensionSecretChannel(extensionStore: extensionStore)
        let store = Self.store(local: local, channel: channel)

        let text = try await store.loadConfigurationText(for: Self.tunnel)

        #expect(text == "local")
        #expect(await channel.deliveredMessageCount == 0)
    }

    @Test
    func refreshesTheExtensionCopyWhenATunnelChanges() async throws {
        let (records, extensionStore) = (InMemoryTunnelRecordRepository(), InMemoryTunnelSecretStore())
        let store = Self.store(
            local: InMemoryTunnelSecretStore(), channel: LoopbackExtensionSecretChannel(extensionStore: extensionStore))
        let original = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        let changed = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.full).configuration)
        let tunnel = try await CreateTunnelUseCase(records: records, secrets: store)
            .execute(name: try TunnelName("Prague"), configuration: original)

        _ = try await UpdateTunnelUseCase(records: records, secrets: store)
            .execute(id: tunnel.id, configuration: changed, routingPolicy: .default)

        #expect(await extensionStore.texts[tunnel.id] == WgQuickConfigurationSerializer.serialize(changed))
    }

    private static func store(
        local: InMemoryTunnelSecretStore,
        channel: LoopbackExtensionSecretChannel,
        failures: AwaitableState<[SecretDeliveryError]> = AwaitableState([])
    ) -> MirroredTunnelSecretStore {
        MirroredTunnelSecretStore(local: local, channel: channel) { error in
            failures.update { recorded in recorded.append(error) }
        }
    }
}
