import Foundation
import TunnelImport
import Vision

public struct VisionQRCodeDecoder: QRCodeDecoder {
    public init() {}

    public func decodeTexts(in imageData: Data) async throws(QRCodeDecodingError) -> [String] {
        var request = DetectBarcodesRequest()
        request.symbologies = [.qr]
        let observations: [BarcodeObservation]
        do {
            observations = try await request.perform(on: imageData)
        } catch {
            throw .unreadableImage
        }
        var seenTexts: Set<String> = []
        return observations.compactMap(\.payloadString).filter { text in seenTexts.insert(text).inserted }
    }
}
