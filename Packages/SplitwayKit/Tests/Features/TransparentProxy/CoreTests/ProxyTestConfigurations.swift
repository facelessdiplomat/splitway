import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

enum ProxyTestConfigurations {
    static func configuration(allowedIPs: String, dnsServers: String? = nil) throws -> TunnelConfiguration {
        let interfaceLines = [
            "[Interface]",
            "PrivateKey = \(SampleKeys.interfacePrivateKeyText)",
            "Address = 10.14.0.2/16",
        ]
        let dnsLines = dnsServers.map { servers in ["DNS = \(servers)"] } ?? []
        let peerLines = [
            "[Peer]",
            "PublicKey = \(SampleKeys.firstPeerPublicKeyText)",
            "AllowedIPs = \(allowedIPs)",
            "Endpoint = 203.0.113.10:51820",
        ]
        let text = (interfaceLines + dnsLines + [""] + peerLines).joined(separator: "\n")
        return try #require(WgQuickConfigurationParser.parse(text).configuration)
    }
}
