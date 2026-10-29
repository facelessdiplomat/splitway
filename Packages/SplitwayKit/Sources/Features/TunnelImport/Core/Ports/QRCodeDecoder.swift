import Foundation

public protocol QRCodeDecoder: Sendable {
    func decodeTexts(in imageData: Data) async throws(QRCodeDecodingError) -> [String]
}
