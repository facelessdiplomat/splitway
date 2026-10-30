import AppRouting
import ProviderMessaging
import Testing
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary

@Suite
struct ApplyRoutingPolicyUseCaseTests {
    private let browsing: Tunnel

    init() throws {
        browsing = try ConnectionTestTunnels.named("Browsing")
            .routed(by: RoutingPolicy(mode: .selectedApplications(ApplicationSelection([]))))
    }

    @Test
    func sendsThePolicyOfTheTunnelToTheRunningProvider() async throws {
        let messenger = RecordingProviderMessenger(outcome: .success(.routingPolicyApplied))

        try await ApplyRoutingPolicyUseCase(messenger: messenger).execute(browsing)

        #expect(await messenger.requests == [.applyRoutingPolicy(policy: browsing.routingPolicy)])
    }

    @Test
    func reportsAPolicyTheProviderRejected() async {
        let messenger = RecordingProviderMessenger(outcome: .success(.failure(reason: .routingPolicyRejected)))

        await #expect(throws: RoutingPolicyApplicationError.rejected) {
            try await ApplyRoutingPolicyUseCase(messenger: messenger).execute(browsing)
        }
    }

    @Test
    func reportsAProviderThatCannotBeReached() async {
        let messenger = RecordingProviderMessenger(outcome: .failure(.extensionUnavailable))

        await #expect(throws: RoutingPolicyApplicationError.providerUnreachable) {
            try await ApplyRoutingPolicyUseCase(messenger: messenger).execute(browsing)
        }
    }
}
