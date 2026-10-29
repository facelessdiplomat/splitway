enum WgQuickInterfaceAssembler {
    static func assemble(_ section: WgQuickRawSection, issues: inout [ConfigurationIssue]) -> InterfaceConfiguration? {
        let reader = WgQuickValueReader(values: WgQuickSectionValues(classifying: section, issues: &issues))
        let privateKey = reader.single(.privateKey, issues: &issues, conversion: WgQuickValueConversions.privateKey)
        let addresses = reader.everyLine(.address, issues: &issues, conversion: WgQuickValueConversions.networks)
        let listenPort = reader.single(.listenPort, issues: &issues, conversion: WgQuickValueConversions.listenPort)
        let mtu = reader.single(.mtu, issues: &issues, conversion: WgQuickValueConversions.mtu)
        let dnsLines = reader.everyLine(.dns, issues: &issues, conversion: WgQuickValueConversions.dns)
        if !reader.values.contains(.privateKey) {
            issues.append(ConfigurationIssue(line: section.headerLine, kind: .missingPrivateKey))
        }
        guard let privateKey else { return nil }
        return InterfaceConfiguration(
            privateKey: privateKey,
            addresses: addresses.flatMap { $0 },
            listenPort: listenPort,
            mtu: mtu,
            dns: DNSConfiguration(
                servers: dnsLines.flatMap(\.servers),
                searchDomains: dnsLines.flatMap(\.searchDomains)
            )
        )
    }
}
