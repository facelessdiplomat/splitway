import Foundation
import TunnelConfiguration

extension PeerRuntimeStatistics: Codable {
    private enum CodingKeys: String, CodingKey {
        case publicKey
        case receivedByteCount
        case transmittedByteCount
        case latestHandshake
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let publicKeyText = try container.decode(String.self, forKey: .publicKey)
        guard let publicKey = try? PublicKey(base64Encoded: publicKeyText) else {
            throw DecodingError.dataCorruptedError(
                forKey: .publicKey,
                in: container,
                debugDescription: "Invalid peer public key"
            )
        }
        self.init(
            publicKey: publicKey,
            receivedByteCount: try container.decode(UInt64.self, forKey: .receivedByteCount),
            transmittedByteCount: try container.decode(UInt64.self, forKey: .transmittedByteCount),
            latestHandshake: try container.decodeIfPresent(Date.self, forKey: .latestHandshake)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(publicKey.base64EncodedText, forKey: .publicKey)
        try container.encode(receivedByteCount, forKey: .receivedByteCount)
        try container.encode(transmittedByteCount, forKey: .transmittedByteCount)
        try container.encodeIfPresent(latestHandshake, forKey: .latestHandshake)
    }
}
