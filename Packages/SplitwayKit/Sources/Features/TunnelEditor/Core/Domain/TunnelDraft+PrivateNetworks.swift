import TunnelConfiguration

extension TunnelDraft {
    private static let listSeparator = ", "

    public func privateNetworkChoice(forPeer id: PeerDraftID) -> PrivateNetworkChoice {
        guard let allowedIPs = allowedIPs(ofPeer: id), PrivateNetworkExclusion.isApplicable(to: allowedIPs) else {
            return .notApplicable
        }
        return PrivateNetworkExclusion.isApplied(to: allowedIPs) ? .excluded : .included
    }

    public mutating func setExcludesPrivateNetworks(_ excludesPrivateNetworks: Bool, forPeer id: PeerDraftID) {
        guard let allowedIPs = allowedIPs(ofPeer: id) else { return }
        let dnsServers = (try? WgQuickValueConversions.dns(interface.dns))?.servers ?? []
        let updated =
            excludesPrivateNetworks
            ? PrivateNetworkExclusion.applying(to: allowedIPs, keepingReachable: dnsServers)
            : PrivateNetworkExclusion.removing(from: allowedIPs, dnsServers: dnsServers)
        let text = updated.networks.map(\.description).joined(separator: Self.listSeparator)
        setText(text, for: .peer(id, .allowedIPs))
    }

    private func allowedIPs(ofPeer id: PeerDraftID) -> AllowedIPs? {
        let text = self.text(for: .peer(id, .allowedIPs))
        return (try? WgQuickValueConversions.networks(text)).map(AllowedIPs.init)
    }
}
