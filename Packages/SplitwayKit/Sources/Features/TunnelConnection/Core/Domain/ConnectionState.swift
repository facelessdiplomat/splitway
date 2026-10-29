import Foundation

public enum ConnectionState: Sendable, Hashable {
    case disconnected
    case connecting
    case connected(since: Date)
    case reasserting
    case disconnecting
    case failed(ConnectionFailure)

    public var isActive: Bool {
        switch self {
        case .connecting, .connected, .reasserting: true
        case .disconnected, .disconnecting, .failed: false
        }
    }

    var isSessionInProgress: Bool {
        isActive || self == .disconnecting
    }

    var isFailure: Bool {
        if case .failed = self { true } else { false }
    }
}
