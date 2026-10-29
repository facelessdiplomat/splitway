import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEditor
import TunnelLibrary

@Suite
struct TunnelDraftValidationTests {
    private static let invalidInterfaceValues: [InvalidFieldValue<InterfaceDraftField>] = [
        InvalidFieldValue(.privateKey, "", .missing),
        InvalidFieldValue(.privateKey, "short", .invalidValue(.key(.malformedBase64))),
        InvalidFieldValue(.addresses, "10.0.0.300/24", .invalidValue(.network(.invalidAddress(.malformedIPv4)))),
        InvalidFieldValue(.listenPort, "70000", .invalidValue(.port(.outOfRange))),
        InvalidFieldValue(.mtu, "9", .invalidValue(.mtu(.outOfRange))),
        InvalidFieldValue(.dns, "not a server!", .invalidValue(.dns(.invalidEntry("not a server!")))),
    ]
    private static let invalidPeerValues: [InvalidFieldValue<PeerDraftField>] = [
        InvalidFieldValue(.publicKey, "", .missing),
        InvalidFieldValue(.presharedKey, "short", .invalidValue(.key(.malformedBase64))),
        InvalidFieldValue(.allowedIPs, "10.0.0.0/40", .invalidValue(.network(.prefixLengthOutOfRange))),
        InvalidFieldValue(.endpoint, "vpn.example.com", .invalidValue(.endpoint(.missingPort))),
        InvalidFieldValue(.persistentKeepalive, "70000", .invalidValue(.persistentKeepalive(.outOfRange))),
    ]

    @Test(arguments: invalidInterfaceValues)
    func reportsAnInvalidInterfaceField(_ invalid: InvalidFieldValue<InterfaceDraftField>) throws {
        var draft = try TunnelDraftFixtures.fullDraft()

        draft.setText(invalid.text, for: .interface(invalid.field))

        #expect(
            draft.validation.problems == [TunnelDraftProblem(field: .interface(invalid.field), reason: invalid.reason)]
        )
        #expect(draft.validation.configuration == nil)
    }

    @Test(arguments: invalidPeerValues)
    func reportsAnInvalidPeerField(_ invalid: InvalidFieldValue<PeerDraftField>) throws {
        var draft = try TunnelDraftFixtures.fullDraft()
        let peer = try #require(draft.peers.first?.id)

        draft.setText(invalid.text, for: .peer(peer, invalid.field))

        #expect(
            draft.validation.problems == [TunnelDraftProblem(field: .peer(peer, invalid.field), reason: invalid.reason)]
        )
    }

    @Test
    func requiresAValidName() throws {
        var draft = try TunnelDraftFixtures.fullDraft()

        draft.name = "   "

        #expect(draft.validation.problems == [TunnelDraftProblem(field: .name, reason: .invalidName(.empty))])
        #expect(draft.validation.configuration != nil)
    }

    @Test
    func reportsOnlyThePeerThatIsInvalid() throws {
        var draft = TunnelDraft(name: "Office", text: WgQuickFixtures.multiplePeers)
        let peers = draft.peers.map(\.id)

        draft.setText("", for: .peer(peers[0], .publicKey))

        #expect(draft.validation.problems == [TunnelDraftProblem(field: .peer(peers[0], .publicKey), reason: .missing)])
        #expect(draft.validation.problems(for: peers[1]).isEmpty)
    }

    @Test
    func reportsTheSecondPeerWithTheSameKey() throws {
        var draft = TunnelDraft(name: "Office", text: WgQuickFixtures.multiplePeers)
        let peers = draft.peers.map(\.id)

        draft.setText(SampleKeys.firstPeerPublicKeyText, for: .peer(peers[1], .publicKey))

        #expect(
            draft.validation.problems == [
                TunnelDraftProblem(field: .peer(peers[1], .publicKey), reason: .duplicatePeerPublicKey)
            ]
        )
    }
}
