import TunnelConfiguration

public enum SampleKeys {
    public static let interfacePrivateKeyText = "dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LCo="
    public static let interfacePublicKeyText = "hSDwCYkwp1R0i33ctD73Wg2/Og0mOBr066SpjqqbTmo="
    public static let firstPeerPublicKeyText = "3p7bfXt9wbTTW2HC7OQ1Nz+DQ8hbeGdNrfx+FG+IK08="
    public static let secondPeerPublicKeyText = "QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVphYmNkZWY="
    public static let presharedKeyText = "XasIfmJKikt54X+Lg4AO5m87sSkmGLb9HC+LJ/+I4Os="

    public static func interfacePrivateKey() throws -> PrivateKey {
        try PrivateKey(base64Encoded: interfacePrivateKeyText)
    }

    public static func interfacePublicKey() throws -> PublicKey {
        try PublicKey(base64Encoded: interfacePublicKeyText)
    }

    public static func firstPeerPublicKey() throws -> PublicKey {
        try PublicKey(base64Encoded: firstPeerPublicKeyText)
    }

    public static func secondPeerPublicKey() throws -> PublicKey {
        try PublicKey(base64Encoded: secondPeerPublicKeyText)
    }

    public static func presharedKey() throws -> PresharedKey {
        try PresharedKey(base64Encoded: presharedKeyText)
    }
}
