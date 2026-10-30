import CryptoKit
import Foundation

enum SecretFingerprint {
    private static let shownByteCount = 4

    static func of(_ secret: Data) -> String {
        SHA256.hash(data: secret).prefix(shownByteCount).map { byte in String(format: "%02x", byte) }.joined()
    }
}
