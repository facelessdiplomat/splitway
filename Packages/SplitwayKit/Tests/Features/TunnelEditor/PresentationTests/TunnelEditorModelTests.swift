import AppRouting
import Foundation
import Testing
import TunnelConfigurationTestSupport
import TunnelConnectionTestSupport
import TunnelEditor
import TunnelEditorPresentation

@MainActor
@Suite
struct TunnelEditorModelTests {
    private static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_900)

    @Test
    func cannotSaveWhileAFieldIsInvalid() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(for: try await environment.storeTunnel(named: "Office"))
        #expect(editor.canSave)

        editor.setText("9", for: .interface(.mtu))

        #expect(!editor.canSave)
        #expect(editor.problems(for: .interface(.mtu)) == [.invalidValue(.mtu(.outOfRange))])
    }

    @Test
    func createsATunnelFromScratch() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.newTunnelEditor()
        #expect(editor.draft.interface.publicKey != nil)

        let peer = editor.addPeer()
        editor.setText(SampleKeys.firstPeerPublicKeyText, for: .peer(peer, .publicKey))
        editor.setText("Prague", for: .name)
        await editor.save()

        #expect(try await environment.storedNames() == ["Prague"])
        #expect(environment.savedTunnels.map(\.name.description) == ["Prague"])
    }

    @Test
    func asksBeforeRestartingAnActiveTunnel() async throws {
        let environment = TunnelEditorTestEnvironment(
            controller: FakeSystemTunnelController(status: .connected(since: Self.connectedMoment))
        )
        let office = try await environment.storeTunnel(named: "Office")
        try await environment.controller.install(office)
        let editor = environment.editor(for: office)
        editor.setText("1280", for: .interface(.mtu))

        await editor.save()

        #expect(editor.isConfirmingRestart)
        #expect(environment.savedTunnels.isEmpty)
        await editor.confirmRestart()
        #expect(environment.savedTunnels.map(\.configuration.interface.mtu?.value) == [1280])
        #expect(await environment.controller.operations == [.install(office.id), .stop, .install(office.id), .start])
    }

    @Test
    func savesAnInactiveTunnelWithoutAsking() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(for: try await environment.storeTunnel(named: "Office"))
        editor.setText("1280", for: .interface(.mtu))

        await editor.save()

        #expect(!editor.isConfirmingRestart)
        #expect(environment.savedTunnels.map(\.configuration.interface.mtu?.value) == [1280])
    }

    @Test
    func keepsTheTunnelWhenTheRestartIsCancelled() async throws {
        let environment = TunnelEditorTestEnvironment(
            controller: FakeSystemTunnelController(status: .connected(since: Self.connectedMoment))
        )
        let office = try await environment.storeTunnel(named: "Office")
        try await environment.controller.install(office)
        let editor = environment.editor(for: office)
        editor.setText("1280", for: .interface(.mtu))
        await editor.save()

        editor.cancelRestart()

        #expect(!editor.isConfirmingRestart)
        #expect(environment.savedTunnels.isEmpty)
    }

    @Test
    func renamesAnExistingTunnel() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(for: try await environment.storeTunnel(named: "Office"))

        editor.setText("Prague", for: .name)
        await editor.save()

        #expect(try await environment.storedNames() == ["Prague"])
        #expect(environment.savedTunnels.map(\.name.description) == ["Prague"])
    }

    @Test
    func editsTheSameFieldsAsText() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(for: try await environment.storeTunnel(named: "Office"))

        editor.showText()
        editor.setRawText(editor.rawText.replacingOccurrences(of: "10.14.0.2/16", with: "10.20.0.2/32"))
        editor.showForm()

        #expect(editor.mode == .form)
        #expect(editor.text(for: .interface(.addresses)) == "10.20.0.2/32")
    }

    @Test
    func cannotSaveTextThatIsInvalid() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(for: try await environment.storeTunnel(named: "Office"))

        editor.showText()
        editor.setRawText("[Interface]\nMTU = 9\n")

        #expect(!editor.canSave)
        #expect(editor.textIssues.contains { issue in issue.line == 2 })
    }

    @Test
    func hidesThePrivateKeyUntilAskedToShowIt() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(for: try await environment.storeTunnel(named: "Office"))
        #expect(!editor.isPrivateKeyRevealed)

        editor.revealPrivateKey()

        #expect(editor.isPrivateKeyRevealed)
    }

    @Test
    func savesTheRoutingPolicyChosenInTheEditor() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(for: try await environment.storeTunnel(named: "Office"))

        editor.routing.selectMode(.selectedApplications)
        await editor.save()

        #expect(environment.savedTunnels.map(\.routingPolicy.mode.kind) == [.selectedApplications])
    }

    @Test
    func savesTheApplicationsOfATunnelSwitchedToAllTraffic() async throws {
        let environment = TunnelEditorTestEnvironment()
        let selection = ApplicationSelection([
            try ApplicationIdentity(kind: .application, displayName: "Browser", path: "/Applications/Browser.app")
        ])
        let browsing = try await environment.storeTunnel(
            named: "Browsing",
            routedBy: RoutingPolicy(mode: .selectedApplications(selection))
        )
        let editor = environment.editor(for: browsing)

        editor.routing.selectMode(.allTraffic)
        await editor.save()

        #expect(environment.savedTunnels.map(\.routingPolicy.mode) == [.allTraffic])
        #expect(environment.savedTunnels.map(\.routingPolicy.applicationSelection) == [selection])
    }
}
