import Foundation

struct LeakScanFixture {
    private static let keyByteCount = 32

    let configurationText: String
    let secrets: [String: Data]

    init() {
        let privateKey = Self.randomKey()
        let presharedKey = Self.randomKey()
        configurationText = """
            [Interface]
            PrivateKey = \(privateKey.base64EncodedString())
            Address = 10.66.0.2/32

            [Peer]
            PublicKey = \(Self.randomKey().base64EncodedString())
            PresharedKey = \(presharedKey.base64EncodedString())
            AllowedIPs = 0.0.0.0/0
            Endpoint = 192.0.2.1:51820
            """
        secrets = ["private key": privateKey, "preshared key": presharedKey]
    }

    private static func randomKey() -> Data {
        Data((0..<keyByteCount).map { _ in UInt8.random(in: .min ... .max) })
    }
}
