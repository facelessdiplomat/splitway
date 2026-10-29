public enum WgQuickConfigurationSerializer {
    private static let listSeparator = ", "

    public static func serialize(_ configuration: TunnelConfiguration) -> String {
        let sections = [interfaceLines(of: configuration.interface)] + configuration.peers.map(peerLines(of:))
        return sections.map { lines in lines.joined(separator: "\n") }.joined(separator: "\n\n") + "\n"
    }

    private static func interfaceLines(of interface: InterfaceConfiguration) -> [String] {
        ["[Interface]", line(.privateKey, interface.privateKey.base64EncodedText)]
            + optionalLine(.address, list(interface.addresses.map(\.description)))
            + optionalLine(.listenPort, interface.listenPort?.description)
            + optionalLine(.mtu, interface.mtu.map { mtu in String(mtu.value) })
            + optionalLine(.dns, list(interface.dns.entries))
    }

    private static func peerLines(of peer: PeerConfiguration) -> [String] {
        ["[Peer]", line(.publicKey, peer.publicKey.base64EncodedText)]
            + optionalLine(.presharedKey, peer.presharedKey?.base64EncodedText)
            + optionalLine(.allowedIPs, list(peer.allowedIPs.networks.map(\.description)))
            + optionalLine(.endpoint, peer.endpoint?.description)
            + optionalLine(
                .persistentKeepalive, peer.persistentKeepalive.map { keepalive in String(keepalive.seconds) })
    }

    private static func line(_ key: WgQuickKey, _ value: String) -> String {
        "\(key.name) = \(value)"
    }

    private static func optionalLine(_ key: WgQuickKey, _ value: String?) -> [String] {
        value.map { value in [line(key, value)] } ?? []
    }

    private static func list(_ items: [String]) -> String? {
        items.isEmpty ? nil : items.joined(separator: listSeparator)
    }
}
