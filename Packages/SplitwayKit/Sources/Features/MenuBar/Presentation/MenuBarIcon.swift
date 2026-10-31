import TunnelLibraryPresentation

public enum MenuBarIcon: Sendable, Hashable {
    case disconnected
    case connecting
    case connected
    case failed

    public init(statuses: [TunnelRowStatus]) {
        if statuses.contains(where: \.isConnected) {
            self = .connected
        } else if statuses.contains(where: \.isChanging) {
            self = .connecting
        } else if statuses.contains(where: \.isFailed) {
            self = .failed
        } else {
            self = .disconnected
        }
    }
}

extension TunnelRowStatus {
    fileprivate var isConnected: Bool {
        connectedSince != nil
    }

    fileprivate var isChanging: Bool {
        switch self {
        case .connecting, .reconnecting, .disconnecting: true
        case .disconnected, .connected, .failed, .unavailable: false
        }
    }

    fileprivate var isFailed: Bool {
        failure != nil
    }
}
