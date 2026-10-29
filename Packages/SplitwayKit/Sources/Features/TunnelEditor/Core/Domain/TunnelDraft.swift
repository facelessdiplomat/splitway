import TunnelConfiguration
import TunnelLibrary

public struct TunnelDraft: Sendable, Equatable {
    public var name: String
    public var interface = InterfaceDraft()
    public private(set) var peers: [PeerDraft] = []
    private var nextPeerNumber = 0

    public init(name: String, text: String) {
        self.name = name
        replaceConfiguration(withText: text)
    }

    public init(name: TunnelName, configuration: TunnelConfiguration) {
        self.init(name: name.description, text: WgQuickConfigurationSerializer.serialize(configuration))
    }

    public var text: String {
        TunnelDraftTextCodec.text(of: interface, peers: peers)
    }

    public var validation: TunnelDraftValidation {
        TunnelDraftValidator.validate(self)
    }

    public func text(for field: TunnelDraftField) -> String {
        switch field {
        case .name: name
        case .interface(let field): interface[field]
        case .peer(let id, let field): peers.first { peer in peer.id == id }?[field] ?? ""
        }
    }

    public mutating func setText(_ text: String, for field: TunnelDraftField) {
        switch field {
        case .name:
            name = text
        case .interface(let field):
            interface[field] = text
        case .peer(let id, let field):
            guard let index = peers.firstIndex(where: { peer in peer.id == id }) else { return }
            peers[index][field] = text
        }
    }

    public mutating func replaceConfiguration(withText text: String) {
        let sections = WgQuickConfigurationParser.rawSections(of: text)
        interface = TunnelDraftTextCodec.interface(in: sections)
        peers = []
        for fields in TunnelDraftTextCodec.peerFields(in: sections) {
            let id = addPeer()
            for (field, value) in fields {
                setText(value, for: .peer(id, field))
            }
        }
    }

    @discardableResult
    public mutating func addPeer() -> PeerDraftID {
        let id = PeerDraftID(value: nextPeerNumber)
        nextPeerNumber += 1
        peers.append(PeerDraft(id: id))
        return id
    }

    public mutating func removePeer(_ id: PeerDraftID) {
        peers.removeAll { peer in peer.id == id }
    }

    public mutating func generatePrivateKey() {
        interface.privateKey = PrivateKey.generate().base64EncodedText
    }
}
