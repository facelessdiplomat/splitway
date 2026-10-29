import Testing
import TunnelConfigurationTestSupport
import TunnelEditorPresentation

@MainActor
@Suite
struct TunnelEditorFlowTests {
    @Test
    func opensAnEditorForANewTunnel() {
        let flow = TunnelEditorTestEnvironment().flow()

        flow.createTunnel()

        #expect(flow.editor?.isNewTunnel == true)
    }

    @Test
    func opensAnEditorForAnExistingTunnel() async throws {
        let environment = TunnelEditorTestEnvironment()
        let flow = environment.flow()

        flow.edit(try await environment.storeTunnel(named: "Office"))

        #expect(flow.editor?.isNewTunnel == false)
        #expect(flow.editor?.text(for: .name) == "Office")
    }

    @Test
    func closesTheEditorOnceTheTunnelIsSaved() async throws {
        let environment = TunnelEditorTestEnvironment()
        let flow = environment.flow()
        flow.edit(try await environment.storeTunnel(named: "Office"))

        await flow.editor?.save()

        #expect(flow.editor == nil)
        #expect(environment.savedTunnels.map(\.name.description) == ["Office"])
    }
}
