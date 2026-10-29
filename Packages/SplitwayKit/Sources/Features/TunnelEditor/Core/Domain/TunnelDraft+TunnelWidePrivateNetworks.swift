extension TunnelDraft {
    public func privateNetworkChoice() -> PrivateNetworkChoice {
        let choices = peers.map { peer in privateNetworkChoice(forPeer: peer.id) }.filter { choice in
            choice != .notApplicable
        }
        guard !choices.isEmpty else { return .notApplicable }
        return choices.allSatisfy { choice in choice == .excluded } ? .excluded : .included
    }

    public mutating func setExcludesPrivateNetworks(_ excludesPrivateNetworks: Bool) {
        for peer in peers where privateNetworkChoice(forPeer: peer.id) != .notApplicable {
            setExcludesPrivateNetworks(excludesPrivateNetworks, forPeer: peer.id)
        }
    }
}
