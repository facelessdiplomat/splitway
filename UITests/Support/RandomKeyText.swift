import Foundation

enum RandomKeyText {
    private static let keyByteCount = 32

    static func make() -> String {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<keyByteCount).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return Data(bytes).base64EncodedString()
    }
}
