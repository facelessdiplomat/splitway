import TunnelConfiguration

public enum UAPIConfigurationEncoder {
    public static func encode(
        _ configuration: TunnelConfiguration,
        resolvedEndpoints: [PublicKey: ResolvedEndpoint]
    ) -> UAPIConfiguration {
        let interfaceLines = interfaceLines(of: configuration.interface)
        let peerLines = configuration.peers.flatMap { peer in
            self.peerLines(of: peer, endpoint: resolvedEndpoints[peer.publicKey])
        }
        return UAPIConfiguration(text: (interfaceLines + peerLines).map { line in line + "\n" }.joined())
    }

    public static func endpointUpdate(
        for configuration: TunnelConfiguration,
        resolvedEndpoints: [PublicKey: ResolvedEndpoint]
    ) -> UAPIConfiguration? {
        let lines = configuration.peers.flatMap { peer -> [String] in
            guard let endpoint = resolvedEndpoints[peer.publicKey] else { return [] }
            return ["public_key=\(peer.publicKey.hexEncodedText)", "endpoint=\(endpoint.uapiText)"]
        }
        guard !lines.isEmpty else { return nil }
        return UAPIConfiguration(text: lines.map { line in line + "\n" }.joined())
    }

    public static func keepaliveUpdate(
        for configuration: TunnelConfiguration,
        interval: PersistentKeepalive
    ) -> UAPIConfiguration? {
        let lines = configuration.peers
            .filter { peer in peer.persistentKeepalive == nil }
            .flatMap { peer in
                ["public_key=\(peer.publicKey.hexEncodedText)", "persistent_keepalive_interval=\(interval.seconds)"]
            }
        guard !lines.isEmpty else { return nil }
        return UAPIConfiguration(text: lines.map { line in line + "\n" }.joined())
    }

    private static func interfaceLines(of interface: InterfaceConfiguration) -> [String] {
        var lines = ["private_key=\(interface.privateKey.hexEncodedText)"]
        if let listenPort = interface.listenPort {
            lines.append("listen_port=\(listenPort)")
        }
        lines.append("replace_peers=true")
        return lines
    }

    private static func peerLines(of peer: PeerConfiguration, endpoint: ResolvedEndpoint?) -> [String] {
        var lines = ["public_key=\(peer.publicKey.hexEncodedText)"]
        if let presharedKey = peer.presharedKey {
            lines.append("preshared_key=\(presharedKey.hexEncodedText)")
        }
        if let endpoint {
            lines.append("endpoint=\(endpoint.uapiText)")
        }
        if let persistentKeepalive = peer.persistentKeepalive {
            lines.append("persistent_keepalive_interval=\(persistentKeepalive.seconds)")
        }
        lines.append("replace_allowed_ips=true")
        lines += peer.allowedIPs.networks.map { network in "allowed_ip=\(network.normalized)" }
        return lines
    }
}
