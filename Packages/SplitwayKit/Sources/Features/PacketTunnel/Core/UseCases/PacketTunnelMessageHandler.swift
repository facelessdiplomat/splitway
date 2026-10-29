import AppRouting
import ProviderMessaging

public struct PacketTunnelMessageHandler: ProviderMessageHandler {
    private let session: PacketTunnelSession

    public init(session: PacketTunnelSession) {
        self.session = session
    }

    public func handle(_ request: ProviderRequest) async -> ProviderResponse {
        switch request {
        case .runtimeStatistics:
            return await statisticsResponse()
        case .healthCheck:
            return .health(isTunnelRunning: await session.isRunning)
        case .applyRoutingPolicy(let policy):
            return policy.mode.kind == .allTraffic ? .routingPolicyApplied : .failure(reason: .routingPolicyRejected)
        }
    }

    private func statisticsResponse() async -> ProviderResponse {
        do {
            return .runtimeStatistics(statistics: try await session.runtimeStatistics())
        } catch .notRunning {
            return .failure(reason: .tunnelNotRunning)
        } catch {
            return .failure(reason: .internalFailure)
        }
    }
}
