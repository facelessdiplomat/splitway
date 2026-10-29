import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEditor
import TunnelLibrary

@Suite
struct TunnelDraftTests {
    @Test
    func startsFromTheFieldsOfAnExistingTunnel() throws {
        let draft = try TunnelDraftFixtures.fullDraft()

        #expect(draft.name == "Office")
        #expect(draft.text(for: .interface(.addresses)) == "10.14.0.2/16, fd00::2/64")
        #expect(draft.text(for: .interface(.mtu)) == "1420")
        #expect(draft.text(for: .interface(.dns)) == "1.1.1.1, 2606:4700:4700::1111, corp.example")
        #expect(draft.peers.map(\.endpoint) == ["[2001:db8::1]:51820"])
    }

    @Test
    func buildsTheConfigurationItStartedFrom() throws {
        let configuration = try TunnelDraftFixtures.configuration(WgQuickFixtures.full)

        let validation = TunnelDraft(name: try TunnelName("Office"), configuration: configuration).validation

        #expect(validation.configuration == configuration)
        #expect(validation.name?.description == "Office")
        #expect(validation.problems.isEmpty)
    }

    @Test
    func showsThePublicKeyOfThePrivateKey() throws {
        let draft = try TunnelDraftFixtures.fullDraft()

        #expect(draft.interface.publicKey == SampleKeys.interfacePublicKeyText)
    }

    @Test
    func showsNoPublicKeyForAnInvalidPrivateKey() throws {
        var draft = try TunnelDraftFixtures.fullDraft()

        draft.setText("not a key", for: .interface(.privateKey))

        #expect(draft.interface.publicKey == nil)
    }

    @Test
    func generatingAPrivateKeyUpdatesThePublicKey() throws {
        var draft = try TunnelDraftFixtures.fullDraft()

        draft.generatePrivateKey()

        let privateKey = try PrivateKey(base64Encoded: draft.interface.privateKey)
        #expect(draft.interface.privateKey != SampleKeys.interfacePrivateKeyText)
        #expect(draft.interface.publicKey == privateKey.publicKey.base64EncodedText)
    }

    @Test
    func addsAndRemovesPeers() throws {
        var draft = try TunnelDraftFixtures.fullDraft()

        let added = draft.addPeer()
        draft.setText(SampleKeys.secondPeerPublicKeyText, for: .peer(added, .publicKey))
        let first = try #require(draft.peers.first?.id)
        draft.removePeer(first)

        #expect(draft.peers.map(\.id) == [added])
        #expect(draft.peers.map(\.publicKey) == [SampleKeys.secondPeerPublicKeyText])
    }

    @Test
    func keepsEveryFieldWhenSwitchingToTextAndBack() throws {
        var draft = try TunnelDraftFixtures.fullDraft()
        draft.setText("9", for: .interface(.mtu))
        let added = draft.addPeer()
        draft.setText("host without port", for: .peer(added, .endpoint))

        var restored = TunnelDraft(name: draft.name, text: draft.text)
        restored.replaceConfiguration(withText: draft.text)

        #expect(restored.interface == draft.interface)
        #expect(restored.peers.map(\.fields) == draft.peers.map(\.fields))
    }

    @Test
    func excludesPrivateNetworksAndBringsThemBack() throws {
        var draft = TunnelDraft(name: "Office", text: WgQuickFixtures.minimal)
        let peer = try #require(draft.peers.first?.id)
        #expect(draft.privateNetworkChoice(forPeer: peer) == .included)

        draft.setExcludesPrivateNetworks(true, forPeer: peer)

        #expect(draft.privateNetworkChoice(forPeer: peer) == .excluded)
        #expect(!draft.text(for: .peer(peer, .allowedIPs)).contains("0.0.0.0/0"))
        draft.setExcludesPrivateNetworks(false, forPeer: peer)
        #expect(draft.text(for: .peer(peer, .allowedIPs)) == "0.0.0.0/0")
    }

    @Test
    func offersNoPrivateNetworkExclusionForASplitTunnel() throws {
        let draft = TunnelDraft(name: "Office", text: WgQuickFixtures.multiplePeers)

        #expect(
            draft.peers.map { peer in draft.privateNetworkChoice(forPeer: peer.id) } == [
                .notApplicable, .notApplicable,
            ])
    }
}
