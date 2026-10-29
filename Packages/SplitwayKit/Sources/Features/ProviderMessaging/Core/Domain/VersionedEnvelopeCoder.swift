import Foundation

struct VersionedEnvelopeCoder: Sendable {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func encode<Payload: Codable>(_ payload: Payload, version: Int) throws(ProviderMessageCodingError) -> Data {
        do {
            return try encoder.encode(ProviderMessageEnvelope(protocolVersion: version, payload: payload))
        } catch {
            throw .unencodableMessage
        }
    }

    func decode<Payload: Codable>(
        _ type: Payload.Type,
        from data: Data,
        expectedVersion: Int
    ) throws(ProviderMessageCodingError) -> Payload {
        guard let version = try? decoder.decode(ProviderMessageVersion.self, from: data).protocolVersion else {
            throw .malformedMessage
        }
        guard version == expectedVersion else { throw .unsupportedProtocolVersion(found: version) }
        guard let envelope = try? decoder.decode(ProviderMessageEnvelope<Payload>.self, from: data) else {
            throw .malformedMessage
        }
        return envelope.payload
    }
}
