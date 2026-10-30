import AppRouting
import ProviderMessaging

public struct TransparentProxyMessageHandler: ProviderMessageHandler {
    private let session: TransparentProxySession

    public init(session: TransparentProxySession) {
        self.session = session
    }

    public func handle(_ request: ProviderRequest) async -> ProviderResponse {
        switch request {
        case .runtimeStatistics:
            statisticsResponse()
        case .healthCheck:
            .health(isTunnelRunning: session.isRunning)
        case .applyRoutingPolicy(let policy):
            policyResponse(applying: policy)
        }
    }

    private func statisticsResponse() -> ProviderResponse {
        do {
            return .runtimeStatistics(statistics: try session.runtimeStatistics())
        } catch .notRunning {
            return .failure(reason: .tunnelNotRunning)
        } catch {
            return .failure(reason: .internalFailure)
        }
    }

    private func policyResponse(applying policy: RoutingPolicy) -> ProviderResponse {
        do {
            try session.apply(policy)
            return .routingPolicyApplied
        } catch .notRunning {
            return .failure(reason: .tunnelNotRunning)
        } catch {
            return .failure(reason: .routingPolicyRejected)
        }
    }
}
