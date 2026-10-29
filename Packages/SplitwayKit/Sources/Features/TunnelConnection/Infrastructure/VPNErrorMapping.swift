import Foundation
import NetworkExtension
import ProviderMessaging
import TunnelConnection

public enum VPNErrorMapping {
    public static func failureOfSaving(_ error: any Error) -> ConnectionFailure {
        let systemError = error as NSError
        let isDeclinedPermission =
            systemError.domain == NEVPNErrorDomain
            && systemError.code == NEVPNError.Code.configurationReadWriteFailed.rawValue
        return isDeclinedPermission ? .permissionDenied : .systemConfigurationUnavailable
    }

    public static func failureOfStarting(_ error: any Error) -> ConnectionFailure {
        .startRejected
    }

    public static func failureOfDisconnect(_ error: any Error) -> ConnectionFailure {
        TunnelStopReason(error: error).map(ConnectionFailure.init(stopReason:)) ?? .unknown
    }
}
