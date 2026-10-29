import TunnelConfiguration
import TunnelLibrary

enum TunnelDraftValidator {
    static func validate(_ draft: TunnelDraft) -> TunnelDraftValidation {
        var reader = DraftFieldReader()
        let name = validatedName(draft.name, reader: &reader)
        let interface = interfaceConfiguration(draft.interface, reader: &reader)
        let peers = draft.peers.map { peer in peerConfiguration(peer, reader: &reader) }
        reportDuplicatePublicKeys(of: draft.peers, configured: peers, reader: &reader)
        let hasConfigurationProblems = reader.problems.contains { problem in problem.field != .name }
        let configuration: TunnelConfiguration? =
            if !hasConfigurationProblems, let interface {
                try? TunnelConfiguration(interface: interface, peers: peers.compactMap { peer in peer })
            } else {
                nil
            }
        return TunnelDraftValidation(name: name, configuration: configuration, problems: reader.problems)
    }

    private static func validatedName(_ text: String, reader: inout DraftFieldReader) -> TunnelName? {
        do {
            return try TunnelName(text)
        } catch {
            reader.report(.invalidName(error), for: .name)
            return nil
        }
    }

    private static func interfaceConfiguration(_ draft: InterfaceDraft, reader: inout DraftFieldReader)
        -> InterfaceConfiguration?
    {
        let privateKey = reader.required(
            draft.privateKey, as: .interface(.privateKey), using: WgQuickValueConversions.privateKey)
        let addresses = reader.optional(
            draft.addresses, as: .interface(.addresses), using: WgQuickValueConversions.networks)
        let listenPort = reader.optional(
            draft.listenPort, as: .interface(.listenPort), using: WgQuickValueConversions.listenPort)
        let mtu = reader.optional(draft.mtu, as: .interface(.mtu), using: WgQuickValueConversions.mtu)
        let dns = reader.optional(draft.dns, as: .interface(.dns), using: WgQuickValueConversions.dns)
        guard let privateKey else { return nil }
        return InterfaceConfiguration(
            privateKey: privateKey,
            addresses: addresses ?? [],
            listenPort: listenPort,
            mtu: mtu,
            dns: dns ?? DNSConfiguration()
        )
    }

    private static func peerConfiguration(_ draft: PeerDraft, reader: inout DraftFieldReader) -> PeerConfiguration? {
        let publicKey = reader.required(
            draft.publicKey, as: .peer(draft.id, .publicKey), using: WgQuickValueConversions.publicKey)
        let presharedKey = reader.optional(
            draft.presharedKey, as: .peer(draft.id, .presharedKey), using: WgQuickValueConversions.presharedKey)
        let allowedIPs = reader.optional(
            draft.allowedIPs, as: .peer(draft.id, .allowedIPs), using: WgQuickValueConversions.networks)
        let endpoint = reader.optional(
            draft.endpoint, as: .peer(draft.id, .endpoint), using: WgQuickValueConversions.endpoint)
        let persistentKeepalive = reader.optional(
            draft.persistentKeepalive,
            as: .peer(draft.id, .persistentKeepalive),
            using: WgQuickValueConversions.persistentKeepalive
        )
        guard let publicKey else { return nil }
        return PeerConfiguration(
            publicKey: publicKey,
            presharedKey: presharedKey,
            allowedIPs: AllowedIPs(allowedIPs ?? []),
            endpoint: endpoint,
            persistentKeepalive: persistentKeepalive.flatMap { keepalive in keepalive }
        )
    }

    private static func reportDuplicatePublicKeys(
        of drafts: [PeerDraft],
        configured peers: [PeerConfiguration?],
        reader: inout DraftFieldReader
    ) {
        var seenPublicKeys: Set<PublicKey> = []
        for (draft, peer) in zip(drafts, peers) {
            guard let peer, !seenPublicKeys.insert(peer.publicKey).inserted else { continue }
            reader.report(.duplicatePeerPublicKey, for: .peer(draft.id, .publicKey))
        }
    }
}
