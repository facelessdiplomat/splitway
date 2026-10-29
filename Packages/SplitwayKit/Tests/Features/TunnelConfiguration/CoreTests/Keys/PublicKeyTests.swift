import Testing
import TunnelConfiguration

@Suite
struct PublicKeyTests {
    private static let rfc7748AlicePublicKey = "hSDwCYkwp1R0i33ctD73Wg2/Og0mOBr066SpjqqbTmo="
    private static let rfc7748AlicePublicKeyHex = "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"

    @Test
    func convertsBetweenBase64AndHexadecimalText() throws {
        let key = try PublicKey(base64Encoded: Self.rfc7748AlicePublicKey)

        #expect(key.hexEncodedText == Self.rfc7748AlicePublicKeyHex)
        #expect(try PublicKey(hexEncoded: Self.rfc7748AlicePublicKeyHex) == key)
    }

    @Test
    func acceptsUppercaseHexadecimalText() throws {
        let key = try PublicKey(hexEncoded: Self.rfc7748AlicePublicKeyHex.uppercased())

        #expect(key.base64EncodedText == Self.rfc7748AlicePublicKey)
    }

    @Test(arguments: [
        "",
        "8520f0",
        String(repeating: "g", count: 64),
        String(repeating: "０", count: 64),
        "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a00",
    ])
    func rejectsMalformedHexadecimalText(_ text: String) {
        #expect(throws: WireGuardKeyParsingError.malformedHex) {
            try PublicKey(hexEncoded: text)
        }
    }

    @Test
    func describesItselfAsBase64BecauseItIsNotSecret() throws {
        #expect(try PublicKey(base64Encoded: Self.rfc7748AlicePublicKey).description == Self.rfc7748AlicePublicKey)
    }
}
