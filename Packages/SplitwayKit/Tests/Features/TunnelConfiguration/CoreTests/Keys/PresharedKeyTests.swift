import Testing
import TunnelConfiguration

@Suite
struct PresharedKeyTests {
    private static let presharedKeyText = "XasIfmJKikt54X+Lg4AO5m87sSkmGLb9HC+LJ/+I4Os="

    @Test
    func roundTripsBase64Text() throws {
        #expect(try PresharedKey(base64Encoded: Self.presharedKeyText).base64EncodedText == Self.presharedKeyText)
    }

    @Test
    func keepsTheSecretOutOfEveryTextualRepresentation() throws {
        let presharedKey = try PresharedKey(base64Encoded: Self.presharedKeyText)
        var dumped = ""
        dump(presharedKey, to: &dumped)

        let renderings = [
            String(describing: presharedKey), String(reflecting: presharedKey), "\(presharedKey)", dumped,
        ]

        for rendering in renderings {
            #expect(!rendering.contains(Self.presharedKeyText))
            #expect(!rendering.contains(presharedKey.hexEncodedText))
        }
    }

    @Test
    func generatesDistinctKeys() {
        #expect(PresharedKey.generate() != PresharedKey.generate())
    }
}
