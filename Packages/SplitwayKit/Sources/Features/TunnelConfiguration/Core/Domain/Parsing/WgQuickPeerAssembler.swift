enum WgQuickPeerAssembler {
    static func assemble(_ section: WgQuickRawSection, issues: inout [ConfigurationIssue]) -> PeerConfiguration? {
        let reader = WgQuickValueReader(values: WgQuickSectionValues(classifying: section, issues: &issues))
        let publicKey = reader.single(.publicKey, issues: &issues, conversion: WgQuickValueConversions.publicKey)
        let presharedKey = reader.single(
            .presharedKey,
            issues: &issues,
            conversion: WgQuickValueConversions.presharedKey
        )
        let allowedIPs = reader.everyLine(.allowedIPs, issues: &issues, conversion: WgQuickValueConversions.networks)
        let endpoint = reader.single(.endpoint, issues: &issues, conversion: WgQuickValueConversions.endpoint)
        let persistentKeepalive = reader.single(
            .persistentKeepalive,
            issues: &issues,
            conversion: WgQuickValueConversions.persistentKeepalive
        )
        if !reader.values.contains(.publicKey) {
            issues.append(ConfigurationIssue(line: section.headerLine, kind: .missingPeerPublicKey))
        }
        guard let publicKey else { return nil }
        return PeerConfiguration(
            publicKey: publicKey,
            presharedKey: presharedKey,
            allowedIPs: AllowedIPs(allowedIPs.flatMap { $0 }),
            endpoint: endpoint,
            persistentKeepalive: persistentKeepalive.flatMap { $0 }
        )
    }
}
