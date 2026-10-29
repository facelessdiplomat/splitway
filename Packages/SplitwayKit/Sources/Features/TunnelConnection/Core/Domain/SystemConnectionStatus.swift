import Foundation

public enum SystemConnectionStatus: Sendable, Hashable {
    case notConfigured
    case disconnected
    case connecting
    case connected(since: Date)
    case reasserting
    case disconnecting

    public var isActive: Bool {
        switch self {
        case .connecting, .connected, .reasserting: true
        case .notConfigured, .disconnected, .disconnecting: false
        }
    }

    var endsSession: Bool {
        switch self {
        case .notConfigured, .disconnected: true
        case .connecting, .connected, .reasserting, .disconnecting: false
        }
    }
}
