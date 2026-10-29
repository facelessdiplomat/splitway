import Foundation
import NetworkExtension
import TunnelConnection

public enum VPNStatusMapping {
    public static func status(
        of vpnStatus: NEVPNStatus,
        connectedDate: Date?,
        fallbackConnectedDate: Date
    ) -> SystemConnectionStatus {
        switch vpnStatus {
        case .invalid: .notConfigured
        case .disconnected: .disconnected
        case .connecting: .connecting
        case .connected: .connected(since: connectedDate ?? fallbackConnectedDate)
        case .reasserting: .reasserting
        case .disconnecting: .disconnecting
        @unknown default: .disconnected
        }
    }
}
