import Foundation
import TunnelImport

struct StubQRCodeDecoder: QRCodeDecoder {
    let result: Result<[String], QRCodeDecodingError>

    init(_ result: Result<[String], QRCodeDecodingError> = .success([])) {
        self.result = result
    }

    func decodeTexts(in imageData: Data) async throws(QRCodeDecodingError) -> [String] {
        try result.get()
    }
}
