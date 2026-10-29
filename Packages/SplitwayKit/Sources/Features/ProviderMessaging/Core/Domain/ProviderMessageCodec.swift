import Foundation

public struct ProviderMessageCodec: Sendable {
    public static let protocolVersion = 1

    private let coder = VersionedEnvelopeCoder()

    public init() {}

    public func encode(_ request: ProviderRequest) throws(ProviderMessageCodingError) -> Data {
        try coder.encode(request, version: Self.protocolVersion)
    }

    public func encode(_ response: ProviderResponse) throws(ProviderMessageCodingError) -> Data {
        try coder.encode(response, version: Self.protocolVersion)
    }

    public func decodeRequest(from message: Data) throws(ProviderMessageCodingError) -> ProviderRequest {
        try coder.decode(ProviderRequest.self, from: message, expectedVersion: Self.protocolVersion)
    }

    public func decodeResponse(from message: Data) throws(ProviderMessageCodingError) -> ProviderResponse {
        try coder.decode(ProviderResponse.self, from: message, expectedVersion: Self.protocolVersion)
    }
}
