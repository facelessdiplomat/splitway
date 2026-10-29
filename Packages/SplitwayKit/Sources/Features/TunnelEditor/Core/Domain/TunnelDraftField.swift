public enum TunnelDraftField: Sendable, Hashable {
    case name
    case interface(InterfaceDraftField)
    case peer(PeerDraftID, PeerDraftField)
}
