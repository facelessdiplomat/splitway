import Foundation
import SecretDelivery
import Testing
import TunnelLibrary
import TunnelLibraryTestSupport

@Suite
struct SecretDeliveryRequestHandlerTests {
    private static let tunnel = TunnelIdentifier()

    @Test
    func storesTheDeliveredSecret() async throws {
        let store = InMemoryTunnelSecretStore()
        let request = SecretDeliveryCodec.data(for: .store(tunnel: Self.tunnel, configurationText: "secret"))

        let reply = await SecretDeliveryRequestHandler(store: store).reply(to: request)

        #expect(try SecretDeliveryCodec.reply(from: reply) == .done)
        #expect(await store.texts[Self.tunnel] == "secret")
    }

    @Test
    func removesTheSecret() async throws {
        let store = InMemoryTunnelSecretStore(texts: [Self.tunnel: "secret"])

        let reply = await SecretDeliveryRequestHandler(store: store).reply(
            to: SecretDeliveryCodec.data(for: .remove(tunnel: Self.tunnel)))

        #expect(try SecretDeliveryCodec.reply(from: reply) == .done)
        #expect(await store.texts[Self.tunnel] == nil)
    }

    @Test(arguments: [
        (#"not json"#, SecretDeliveryFailure.malformedMessage),
        (#"{"schemaVersion":7,"kind":"remove"}"#, SecretDeliveryFailure.unsupportedSchemaVersion),
    ])
    func answersARequestItCannotReadWithAFailure(text: String, failure: SecretDeliveryFailure) async throws {
        let reply = await SecretDeliveryRequestHandler(store: InMemoryTunnelSecretStore()).reply(to: Data(text.utf8))

        #expect(try SecretDeliveryCodec.reply(from: reply) == .failed(failure))
    }

    @Test
    func reportsAStorageFailure() async throws {
        let store = InMemoryTunnelSecretStore()
        await store.failSave(number: 1)

        let reply = await SecretDeliveryRequestHandler(store: store).reply(
            to: SecretDeliveryCodec.data(for: .store(tunnel: Self.tunnel, configurationText: "secret")))

        #expect(try SecretDeliveryCodec.reply(from: reply) == .failed(.storageUnavailable))
    }
}
