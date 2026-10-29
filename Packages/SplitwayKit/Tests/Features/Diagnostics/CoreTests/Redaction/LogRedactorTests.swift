import CryptoKit
import Diagnostics
import Foundation
import Testing

@Suite
struct LogRedactorTests {
    private static let lookalikes: [String] = [
        String(repeating: "A", count: 43),
        String(repeating: "A", count: 43) + "==",
        String(repeating: "A", count: 42) + "B=",
        String(repeating: "A", count: 44) + "=",
        Data(repeating: 7, count: 64).base64EncodedString(),
        String(repeating: "ab", count: 31) + "a",
        String(repeating: "ab", count: 32) + "a",
        "0x" + String(repeating: "ab", count: 32),
        "6F9619FF-8B86-D011-B42D-00C04FC964FF",
        "PrivateKeyFile = /etc/wireguard/private.key",
        "PublicKey = not-a-secret",
        "ключ без секрета",
    ]

    private let privateKey = Curve25519.KeyAgreement.PrivateKey()
    private let presharedKey = SymmetricKey(size: .bits256)

    @Test
    func masksAKeyInTheMiddleOfALine() {
        #expect(LogRedactor.redact("handshake with \(publicKeyText) failed") == "handshake with [redacted] failed")
    }

    @Test
    func masksEveryKeyOfAText() {
        #expect(LogRedactor.redact("\(privateKeyText) then \(publicKeyText).") == "[redacted] then [redacted].")
    }

    @Test
    func masksHexEncodedKeys() {
        let uapiText =
            "private_key=\(privateKeyHexText)\nlisten_port=51820\npublic_key=\(privateKeyHexText.uppercased())"

        #expect(LogRedactor.redact(uapiText) == "private_key=[redacted]\nlisten_port=51820\npublic_key=[redacted]")
    }

    @Test
    func masksEveryKeyOfAConfiguration() {
        let configuration = """
            [Interface]
            PrivateKey = \(privateKeyText)
            Address = 10.0.0.2/32

            [Peer]
            PublicKey = \(publicKeyText)
            PresharedKey = \(presharedKeyText)
            Endpoint = vpn.example.com:51820
            """

        #expect(
            LogRedactor.redact(configuration) == """
                [Interface]
                PrivateKey = [redacted]
                Address = 10.0.0.2/32

                [Peer]
                PublicKey = [redacted]
                PresharedKey = [redacted]
                Endpoint = vpn.example.com:51820
                """
        )
    }

    @Test
    func masksMalformedValuesOfSecretKeys() {
        #expect(LogRedactor.redact("privatekey: tooShort") == "privatekey: [redacted]")
        #expect(LogRedactor.redact("PresharedKey=abc def") == "PresharedKey=[redacted] def")
    }

    @Test
    func keepsTextAroundKeysIntact() {
        #expect(LogRedactor.redact("ключ \(privateKeyText) — ок") == "ключ [redacted] — ок")
    }

    @Test(arguments: lookalikes)
    func leavesLookalikesUntouched(_ text: String) {
        #expect(LogRedactor.redact(text) == text)
    }

    private var privateKeyText: String {
        privateKey.rawRepresentation.base64EncodedString()
    }

    private var privateKeyHexText: String {
        privateKey.rawRepresentation.map { byte in String(format: "%02x", byte) }.joined()
    }

    private var publicKeyText: String {
        privateKey.publicKey.rawRepresentation.base64EncodedString()
    }

    private var presharedKeyText: String {
        presharedKey.withUnsafeBytes { bytes in Data(bytes).base64EncodedString() }
    }
}
