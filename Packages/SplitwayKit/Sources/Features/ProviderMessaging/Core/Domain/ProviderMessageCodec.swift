import Foundation

public struct ProviderMessageCodec: Sendable {
    public static let protocolVersion = 1

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {}

    public func encode(_ request: ProviderRequest) throws(ProviderMessageCodingError) -> Data {
        try encodeEnvelope(of: request)
    }

    public func encode(_ response: ProviderResponse) throws(ProviderMessageCodingError) -> Data {
        try encodeEnvelope(of: response)
    }

    public func decodeRequest(from message: Data) throws(ProviderMessageCodingError) -> ProviderRequest {
        try decodePayload(ProviderRequest.self, from: message)
    }

    public func decodeResponse(from message: Data) throws(ProviderMessageCodingError) -> ProviderResponse {
        try decodePayload(ProviderResponse.self, from: message)
    }

    private func encodeEnvelope<Payload: Codable>(of payload: Payload) throws(ProviderMessageCodingError) -> Data {
        do {
            return try encoder.encode(ProviderMessageEnvelope(protocolVersion: Self.protocolVersion, payload: payload))
        } catch {
            throw .unencodableMessage
        }
    }

    private func decodePayload<Payload: Codable>(
        _ type: Payload.Type,
        from message: Data
    ) throws(ProviderMessageCodingError) -> Payload {
        guard let version = try? decoder.decode(ProviderMessageVersion.self, from: message).protocolVersion else {
            throw .malformedMessage
        }
        guard version == Self.protocolVersion else { throw .unsupportedProtocolVersion(found: version) }
        guard let envelope = try? decoder.decode(ProviderMessageEnvelope<Payload>.self, from: message) else {
            throw .malformedMessage
        }
        return envelope.payload
    }
}
