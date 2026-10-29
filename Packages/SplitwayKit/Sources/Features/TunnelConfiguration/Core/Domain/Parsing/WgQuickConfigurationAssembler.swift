enum WgQuickConfigurationAssembler {
    private struct AssembledPeer {
        let configuration: PeerConfiguration
        let headerLine: Int
    }

    static func assemble(_ sections: [WgQuickRawSection], issues: inout [ConfigurationIssue]) -> TunnelConfiguration? {
        let interfaceSections = sections.filter { $0.section == .interface }
        if interfaceSections.isEmpty {
            issues.append(ConfigurationIssue(line: nil, kind: .missingInterfaceSection))
        }
        for extraSection in interfaceSections.dropFirst() {
            issues.append(ConfigurationIssue(line: extraSection.headerLine, kind: .multipleInterfaceSections))
        }
        let interface = interfaceSections.first.flatMap { WgQuickInterfaceAssembler.assemble($0, issues: &issues) }
        let peers = assemblePeers(sections.filter { $0.section == .peer }, issues: &issues)
        guard let interface, !issues.contains(where: { $0.severity == .error }),
            let configuration = try? TunnelConfiguration(interface: interface, peers: peers.map(\.configuration))
        else { return nil }
        issues += warnings(of: configuration, interfaceLine: interfaceSections.first?.headerLine, peers: peers)
        return configuration
    }

    private static func assemblePeers(
        _ sections: [WgQuickRawSection],
        issues: inout [ConfigurationIssue]
    ) -> [AssembledPeer] {
        var peers: [AssembledPeer] = []
        var seenPublicKeys: Set<PublicKey> = []
        for section in sections {
            guard let peer = WgQuickPeerAssembler.assemble(section, issues: &issues) else { continue }
            guard seenPublicKeys.insert(peer.publicKey).inserted else {
                issues.append(
                    ConfigurationIssue(line: section.headerLine, kind: .duplicatePeerPublicKey(peer.publicKey)))
                continue
            }
            peers.append(AssembledPeer(configuration: peer, headerLine: section.headerLine))
        }
        return peers
    }

    private static func warnings(
        of configuration: TunnelConfiguration,
        interfaceLine: Int?,
        peers: [AssembledPeer]
    ) -> [ConfigurationIssue] {
        configuration.warnings.map { warning in
            ConfigurationIssue(
                line: line(of: warning, interfaceLine: interfaceLine, peers: peers),
                kind: .configurationWarning(warning))
        }
    }

    private static func line(
        of warning: TunnelConfigurationWarning,
        interfaceLine: Int?,
        peers: [AssembledPeer]
    ) -> Int? {
        switch warning {
        case .noPeers:
            nil
        case .interfaceWithoutAddresses:
            interfaceLine
        case .peerUsesInterfacePublicKey(let publicKey), .peerWithoutAllowedIPs(let publicKey):
            peers.first { $0.configuration.publicKey == publicKey }?.headerLine
        }
    }
}
