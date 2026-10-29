import TunnelConfiguration

enum TunnelDraftTextCodec {
    private static let listSeparator = ", "

    static func text(of interface: InterfaceDraft, peers: [PeerDraft]) -> String {
        let interfaceLines =
            ["[Interface]"] + InterfaceDraftField.allCases.compactMap { field in line(field.key, interface[field]) }
        let peerSections = peers.map { peer in
            ["[Peer]"] + PeerDraftField.allCases.compactMap { field in line(field.key, peer[field]) }
        }
        return ([interfaceLines] + peerSections).map { lines in lines.joined(separator: "\n") }
            .joined(separator: "\n\n") + "\n"
    }

    static func interface(in sections: [WgQuickRawSection]) -> InterfaceDraft {
        var interface = InterfaceDraft()
        let entries = sections.first { section in section.section == .interface }?.entries ?? []
        for entry in entries {
            guard let key = WgQuickKey(name: entry.key), let field = InterfaceDraftField(key: key) else { continue }
            interface[field] = merged(interface[field], with: entry.value, isList: field.isList)
        }
        return interface
    }

    static func peerFields(in sections: [WgQuickRawSection]) -> [[PeerDraftField: String]] {
        sections.filter { section in section.section == .peer }.map { section in
            var fields: [PeerDraftField: String] = [:]
            for entry in section.entries {
                guard let key = WgQuickKey(name: entry.key), let field = PeerDraftField(key: key) else { continue }
                fields[field] = merged(fields[field] ?? "", with: entry.value, isList: field.isList)
            }
            return fields
        }
    }

    private static func line(_ key: WgQuickKey, _ value: String) -> String? {
        let singleLineValue = value.split(whereSeparator: \.isNewline).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        return singleLineValue.isEmpty ? nil : "\(key.name) = \(singleLineValue)"
    }

    private static func merged(_ current: String, with addition: String, isList: Bool) -> String {
        guard !current.isEmpty else { return addition }
        return isList ? current + listSeparator + addition : current
    }
}
