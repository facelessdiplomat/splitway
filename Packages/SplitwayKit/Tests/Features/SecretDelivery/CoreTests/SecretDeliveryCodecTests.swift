import Foundation
import SecretDelivery
import Testing
import TunnelConfigurationTestSupport
import TunnelLibrary

@Suite
struct SecretDeliveryCodecTests {
    private static let tunnel = TunnelIdentifier()
    private static let configurationText = "[Interface]\nPrivateKey = \(SampleKeys.interfacePrivateKeyText)\n"

    @Test(arguments: [
        SecretDeliveryMessage.store(tunnel: tunnel, configurationText: configurationText),
        SecretDeliveryMessage.remove(tunnel: tunnel),
        SecretDeliveryMessage.removeAll,
    ])
    func decodesTheMessageItEncoded(message: SecretDeliveryMessage) throws {
        let data = SecretDeliveryCodec.data(for: message)

        #expect(try SecretDeliveryCodec.message(from: data) == message)
    }

    @Test(arguments: [
        SecretDeliveryReply.done, .failed(.storageUnavailable), .failed(.malformedMessage),
        .failed(.unsupportedSchemaVersion),
    ])
    func decodesTheReplyItEncoded(reply: SecretDeliveryReply) throws {
        let data = SecretDeliveryCodec.data(for: reply)

        #expect(try SecretDeliveryCodec.reply(from: data) == reply)
    }

    @Test
    func rejectsAMessageOfAnotherSchemaVersion() {
        let data = Data(#"{"schemaVersion":2,"kind":"remove","tunnel":"\#(Self.tunnel.rawValue)"}"#.utf8)

        #expect(throws: SecretDeliveryCodingError.unsupportedSchemaVersion) {
            try SecretDeliveryCodec.message(from: data)
        }
    }

    @Test(arguments: [
        #"not json"#, #"{"schemaVersion":1,"kind":"store"}"#, #"{"schemaVersion":1,"kind":"done"}"#,
    ])
    func rejectsAMalformedMessage(text: String) {
        #expect(throws: SecretDeliveryCodingError.malformed) {
            try SecretDeliveryCodec.message(from: Data(text.utf8))
        }
    }

    @Test
    func neverShowsTheConfigurationTextInDescriptions() {
        let message = SecretDeliveryMessage.store(tunnel: Self.tunnel, configurationText: Self.configurationText)

        #expect(!String(describing: message).contains(SampleKeys.interfacePrivateKeyText))
        #expect(!String(reflecting: message).contains(SampleKeys.interfacePrivateKeyText))
        #expect(Mirror(reflecting: message).children.isEmpty)
    }
}
