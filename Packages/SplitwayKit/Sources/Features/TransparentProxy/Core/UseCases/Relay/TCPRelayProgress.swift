import Foundation
import TunnelEngine

struct TCPRelayProgress: Sendable {
    private(set) var connection: (any UserspaceConnection)?
    private var onFinish: (@Sendable () -> Void)?
    private var lastActivity: Date
    private var pendingAppWrites = 0
    private var hasTunnelEnded = false
    private var isAppWriteClosed = false
    private var hasAppEnded = false
    private var isFinished = false

    init(startingAt moment: Date) {
        lastActivity = moment
    }

    var activeConnection: (any UserspaceConnection)? {
        isFinished ? nil : connection
    }

    func isIdle(at moment: Date, timeout: Duration) -> Bool {
        !isFinished && Duration.seconds(moment.timeIntervalSince(lastActivity)) >= timeout
    }

    mutating func start(at moment: Date, onFinish: @escaping @Sendable () -> Void) {
        self.onFinish = onFinish
        lastActivity = moment
    }

    mutating func adopt(_ connection: any UserspaceConnection) -> Bool {
        guard !isFinished else { return false }
        self.connection = connection
        return true
    }

    mutating func recordActivity(at moment: Date) {
        lastActivity = moment
    }

    mutating func beginAppWrite(at moment: Date) -> Bool {
        guard !isFinished else { return false }
        pendingAppWrites += 1
        lastActivity = moment
        return true
    }

    mutating func completeAppWrite() -> Bool {
        pendingAppWrites -= 1
        return claimAppWriteClosing()
    }

    mutating func endTunnel() -> Bool {
        guard !isFinished else { return false }
        hasTunnelEnded = true
        return claimAppWriteClosing()
    }

    mutating func endApp() {
        hasAppEnded = true
    }

    mutating func finishIfBothSidesEnded() -> RelayFinishing? {
        guard hasAppEnded, isAppWriteClosed else { return nil }
        return finish()
    }

    mutating func finish() -> RelayFinishing? {
        guard !isFinished else { return nil }
        isFinished = true
        return RelayFinishing(connections: connection.map { [$0] } ?? [], onFinish: onFinish)
    }

    private mutating func claimAppWriteClosing() -> Bool {
        guard hasTunnelEnded, pendingAppWrites == 0, !isAppWriteClosed, !isFinished else { return false }
        isAppWriteClosed = true
        return true
    }
}
