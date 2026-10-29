import Foundation
import Testing
import TunnelConfiguration

@Suite
struct PrivateKeyTests {
    private static let rfc7748AlicePrivateKey = "dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LCo="

    @Test(arguments: [
        ("dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LCo=", "hSDwCYkwp1R0i33ctD73Wg2/Og0mOBr066SpjqqbTmo="),
        ("XasIfmJKikt54X+Lg4AO5m87sSkmGLb9HC+LJ/+I4Os=", "3p7bfXt9wbTTW2HC7OQ1Nz+DQ8hbeGdNrfx+FG+IK08="),
    ])
    func derivesThePublicKeyOfRFC7748Vectors(privateKey: String, publicKey: String) throws {
        #expect(try PrivateKey(base64Encoded: privateKey).publicKey.base64EncodedText == publicKey)
    }

    @Test(arguments: [
        "",
        "AAAA",
        "dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LCo",
        "dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LCo==",
        "dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LC!=",
        "dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LCp=",
        " dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LCo=",
    ])
    func rejectsTextThatIsNotCanonicalBase64(_ text: String) {
        #expect(throws: WireGuardKeyParsingError.malformedBase64) {
            try PrivateKey(base64Encoded: text)
        }
    }

    @Test
    func rejectsBase64OfTheWrongLength() {
        let thirtyThreeBytes = Data(count: 33).base64EncodedString()

        #expect(throws: WireGuardKeyParsingError.invalidLength) {
            try PrivateKey(base64Encoded: thirtyThreeBytes)
        }
    }

    @Test
    func keepsTheSecretOutOfEveryTextualRepresentation() throws {
        let privateKey = try PrivateKey(base64Encoded: Self.rfc7748AlicePrivateKey)
        var dumped = ""
        dump(privateKey, to: &dumped)

        let renderings = [
            String(describing: privateKey), String(reflecting: privateKey), "\(privateKey)", "\([privateKey])", dumped,
        ]

        for rendering in renderings {
            #expect(!rendering.contains(Self.rfc7748AlicePrivateKey))
            #expect(!rendering.contains(privateKey.hexEncodedText))
        }
    }

    @Test
    func exposesTheSecretOnlyThroughExplicitEncodings() throws {
        let privateKey = try PrivateKey(base64Encoded: Self.rfc7748AlicePrivateKey)

        #expect(privateKey.base64EncodedText == Self.rfc7748AlicePrivateKey)
        #expect(privateKey.hexEncodedText == "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a")
    }

    @Test
    func generatesDistinctKeysWhosePublicKeysCanBeDerivedAgain() throws {
        let first = PrivateKey.generate()
        let second = PrivateKey.generate()

        #expect(first != second)
        #expect(try PrivateKey(base64Encoded: first.base64EncodedText).publicKey == first.publicKey)
    }
}
