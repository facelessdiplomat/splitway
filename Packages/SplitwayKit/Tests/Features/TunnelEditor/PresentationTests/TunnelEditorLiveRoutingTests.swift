import AppRouting
import Foundation
import ProviderMessaging
import Testing
import TunnelConnectionTestSupport
import TunnelEditorPresentation
import TunnelLibrary

@MainActor
@Suite
struct TunnelEditorLiveRoutingTests {
    private static let connectedMoment = Date(timeIntervalSince1970: 1_793_268_000)
    private static let applications = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([])))

    @Test
    func appliesANewSelectionOfTheActiveTunnelWithoutRestarting() async throws {
        let environment = TunnelEditorTestEnvironment(
            controller: FakeSystemTunnelController(status: .connected(since: Self.connectedMoment))
        )
        let browsing = try await environment.storeTunnel(named: "Browsing", routedBy: Self.applications)
        try await environment.controller.install(browsing)
        let editor = environment.editor(for: browsing)
        let selection = ApplicationSelection([try Self.browser()])
        editor.routing.setApplications(selection)

        await editor.save()

        #expect(!editor.isConfirmingRestart)
        #expect(environment.savedTunnels.map(\.routingPolicy.mode) == [.selectedApplications(selection)])
        #expect(
            await environment.messenger.requests
                == environment.savedTunnels.map { tunnel in .applyRoutingPolicy(policy: tunnel.routingPolicy) })
        #expect(await environment.controller.operations == [.install(browsing.id)])
    }

    @Test
    func asksToRestartWhenTheProviderCannotApplyTheSelection() async throws {
        let environment = TunnelEditorTestEnvironment(
            controller: FakeSystemTunnelController(status: .connected(since: Self.connectedMoment)),
            providerOutcome: .failure(.extensionUnavailable)
        )
        let browsing = try await environment.storeTunnel(named: "Browsing", routedBy: Self.applications)
        try await environment.controller.install(browsing)
        let editor = environment.editor(for: browsing)
        editor.routing.setApplications(ApplicationSelection([try Self.browser()]))

        await editor.save()

        #expect(editor.isConfirmingRestart)
        #expect(environment.savedTunnels.isEmpty)
    }

    private static func browser() throws -> ApplicationIdentity {
        try ApplicationIdentity(kind: .application, displayName: "Browser", path: "/Applications/Browser.app")
    }
}
