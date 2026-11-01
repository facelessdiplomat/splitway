import AppRouting
import ProviderMessaging

public struct PacketTunnelMessageHandler: ProviderMessageHandler {
    private let session: PacketTunnelSession
    private let networkSettings: any NetworkSettingsApplier

    public init(session: PacketTunnelSession, networkSettings: any NetworkSettingsApplier) {
        self.session = session
        self.networkSettings = networkSettings
    }

    public nonisolated(nonsending) func handle(_ request: ProviderRequest) async -> ProviderResponse {
        switch request {
        case .runtimeStatistics:
            return await statisticsResponse()
        case .healthCheck:
            return .health(isTunnelRunning: await session.isRunning)
        case .applyRoutingPolicy(let policy):
            return await policyResponse(applying: policy)
        }
    }

    private nonisolated(nonsending) func statisticsResponse() async -> ProviderResponse {
        do {
            return .runtimeStatistics(statistics: try await session.runtimeStatistics())
        } catch .notRunning {
            return .failure(reason: .tunnelNotRunning)
        } catch {
            return .failure(reason: .internalFailure)
        }
    }

    private nonisolated(nonsending) func policyResponse(applying policy: RoutingPolicy) async -> ProviderResponse {
        do {
            let change = try await session.routingChange(to: policy)
            if let networkPlan = change.changedNetworkPlan {
                try await networkSettings.apply(networkPlan)
            }
            try await session.complete(change)
            return .routingPolicyApplied
        } catch .notRunning {
            return .failure(reason: .tunnelNotRunning)
        } catch {
            return .failure(reason: .routingPolicyRejected)
        }
    }
}
