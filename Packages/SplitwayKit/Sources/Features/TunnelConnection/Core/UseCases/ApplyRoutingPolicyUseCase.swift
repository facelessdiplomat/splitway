import ProviderMessaging
import TunnelLibrary

public struct ApplyRoutingPolicyUseCase: Sendable {
    private let messenger: any ProviderMessenger

    public init(messenger: any ProviderMessenger) {
        self.messenger = messenger
    }

    public func execute(_ tunnel: Tunnel) async throws(RoutingPolicyApplicationError) {
        let response: ProviderResponse
        do {
            response = try await messenger.send(.applyRoutingPolicy(policy: tunnel.routingPolicy))
        } catch {
            throw .providerUnreachable
        }
        guard response == .routingPolicyApplied else { throw .rejected }
    }
}
