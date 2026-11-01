import Foundation

public enum SecretDeliveryCodec {
    public static let schemaVersion = 1

    public static func data(for message: SecretDeliveryMessage) -> Data {
        switch message {
        case .store(let tunnel, let configurationText):
            encoded(SecretDeliveryEnvelope(kind: .store, tunnel: tunnel, configurationText: configurationText))
        case .remove(let tunnel):
            encoded(SecretDeliveryEnvelope(kind: .remove, tunnel: tunnel))
        case .removeAll:
            encoded(SecretDeliveryEnvelope(kind: .removeAll))
        }
    }

    public static func data(for reply: SecretDeliveryReply) -> Data {
        switch reply {
        case .done: encoded(SecretDeliveryEnvelope(kind: .done))
        case .failed(let failure): encoded(SecretDeliveryEnvelope(kind: .failed, failure: failure))
        }
    }

    public static func message(from data: Data) throws(SecretDeliveryCodingError) -> SecretDeliveryMessage {
        let envelope = try decoded(data)
        switch (envelope.kind, envelope.tunnel, envelope.configurationText) {
        case (.store, .some(let tunnel), .some(let configurationText)):
            return .store(tunnel: tunnel, configurationText: configurationText)
        case (.remove, .some(let tunnel), _):
            return .remove(tunnel: tunnel)
        case (.removeAll, _, _):
            return .removeAll
        default:
            throw .malformed
        }
    }

    public static func reply(from data: Data) throws(SecretDeliveryCodingError) -> SecretDeliveryReply {
        let envelope = try decoded(data)
        switch (envelope.kind, envelope.failure) {
        case (.done, _): return .done
        case (.failed, .some(let failure)): return .failed(failure)
        default: throw .malformed
        }
    }

    private static func encoded(_ envelope: SecretDeliveryEnvelope) -> Data {
        (try? JSONEncoder().encode(envelope)) ?? Data()
    }

    private static func decoded(_ data: Data) throws(SecretDeliveryCodingError) -> SecretDeliveryEnvelope {
        guard let version = try? JSONDecoder().decode(SecretDeliveryEnvelope.Version.self, from: data) else {
            throw .malformed
        }
        guard version.schemaVersion == schemaVersion else { throw .unsupportedSchemaVersion }
        guard let envelope = try? JSONDecoder().decode(SecretDeliveryEnvelope.self, from: data) else {
            throw .malformed
        }
        return envelope
    }
}
