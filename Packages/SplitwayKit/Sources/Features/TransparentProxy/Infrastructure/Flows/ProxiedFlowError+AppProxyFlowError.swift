import NetworkExtension
import TransparentProxy

extension ProxiedFlowError {
    private static let errorsByCode: [NEAppProxyFlowError.Code: ProxiedFlowError] = [
        .refused: .refused,
        .timedOut: .timedOut,
        .peerReset: .peerReset,
    ]

    public init(appProxyError error: any Error) {
        guard let flowError = error as? NEAppProxyFlowError else {
            self = .aborted
            return
        }
        self = Self.errorsByCode[flowError.code] ?? .aborted
    }

    public var appProxyError: NEAppProxyFlowError {
        switch self {
        case .refused: NEAppProxyFlowError(.refused)
        case .timedOut: NEAppProxyFlowError(.timedOut)
        case .peerReset: NEAppProxyFlowError(.peerReset)
        case .aborted: NEAppProxyFlowError(.aborted)
        }
    }
}
