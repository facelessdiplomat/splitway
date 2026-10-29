import DesignSystemPresentation
import Foundation
import TunnelConnection

public enum TunnelRowStatus: Sendable, Hashable {
    case disconnected
    case connecting
    case connected(since: Date)
    case reconnecting
    case disconnecting
    case failed(ConnectionFailure)
    case unavailable

    public init(_ state: ConnectionState) {
        switch state {
        case .disconnected: self = .disconnected
        case .connecting: self = .connecting
        case .connected(let since): self = .connected(since: since)
        case .reasserting: self = .reconnecting
        case .disconnecting: self = .disconnecting
        case .failed(let failure): self = .failed(failure)
        }
    }

    public var isActive: Bool {
        switch self {
        case .connecting, .connected, .reconnecting: true
        case .disconnected, .disconnecting, .failed, .unavailable: false
        }
    }

    public var reportsStatistics: Bool {
        switch self {
        case .connected, .reconnecting: true
        case .disconnected, .connecting, .disconnecting, .failed, .unavailable: false
        }
    }

    public var connectedSince: Date? {
        if case .connected(let since) = self { since } else { nil }
    }

    public var tone: StatusTone {
        switch self {
        case .disconnected: .neutral
        case .connecting, .reconnecting, .disconnecting: .progress
        case .connected: .positive
        case .failed: .critical
        case .unavailable: .warning
        }
    }
}
