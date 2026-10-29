import SharedKernelTestSupport
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct WgQuickParserFuzzTests {
    private static let iterationCount = 10_000
    private static let maximumTokensPerInput = 40
    private static let tokens = [
        "[Interface]", "[Peer]", "[Bogus]", "[", "]", "PrivateKey", "PublicKey", "PresharedKey", "AllowedIPs",
        "Address", "DNS", "Endpoint", "MTU", "ListenPort", "PersistentKeepalive", "PostUp", "Jc", " = ", "=",
        ",", "#", "\n", "\r\n", " ", "\t", "\u{FEFF}", "é", "\u{0}", SampleKeys.interfacePrivateKeyText,
        SampleKeys.firstPeerPublicKeyText, "10.0.0.1/24", "::/0", "vpn.example.com:51820", "[2001:db8::1]:51820",
        "off", "25", "65536", "-1",
    ]

    @Test
    func neverCrashesAndOnlyBuildsConfigurationsWithoutErrors() {
        var generator = SeededRandomNumberGenerator(seed: 2026)

        for _ in 0..<Self.iterationCount {
            let tokenCount = Int.random(in: 0...Self.maximumTokensPerInput, using: &generator)
            let text = (0..<tokenCount).compactMap { _ in Self.tokens.randomElement(using: &generator) }.joined()

            let result = WgQuickConfigurationParser.parse(text)

            let hasErrors = result.issues.contains { $0.severity == .error }
            #expect((result.configuration == nil) == hasErrors)
        }
    }
}
