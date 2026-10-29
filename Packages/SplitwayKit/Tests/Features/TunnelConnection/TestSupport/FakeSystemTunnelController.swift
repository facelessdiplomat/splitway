import TunnelConnection
import TunnelLibrary

public actor FakeSystemTunnelController: SystemTunnelController {
    public enum Operation: Equatable, Sendable {
        case install(TunnelIdentifier)
        case start
        case stop
    }

    public private(set) var operations: [Operation] = []
    public private(set) var status: SystemConnectionStatus
    private var installed: TunnelIdentifier?
    private let installFailure: ConnectionFailure?
    private let disconnectFailure: ConnectionFailure?
    private var isNextInstallHeld = false
    private var heldInstall: CheckedContinuation<Void, Never>?
    private var installHoldWaiters: [CheckedContinuation<Void, Never>] = []
    private let updates: AsyncStream<SystemConnectionStatus>
    private let updatesContinuation: AsyncStream<SystemConnectionStatus>.Continuation

    public init(
        installed: TunnelIdentifier? = nil,
        status: SystemConnectionStatus = .disconnected,
        installFailure: ConnectionFailure? = nil,
        disconnectFailure: ConnectionFailure? = nil
    ) {
        self.installed = installed
        self.status = status
        self.installFailure = installFailure
        self.disconnectFailure = disconnectFailure
        (updates, updatesContinuation) = AsyncStream.makeStream()
    }

    public func installedTunnel() -> TunnelIdentifier? {
        installed
    }

    public func currentStatus() -> SystemConnectionStatus {
        status
    }

    public nonisolated func statusUpdates() -> AsyncStream<SystemConnectionStatus> {
        updates
    }

    public func lastDisconnectFailure() -> ConnectionFailure? {
        disconnectFailure
    }

    public func install(_ tunnel: Tunnel) async throws(ConnectionFailure) {
        operations.append(.install(tunnel.id))
        if isNextInstallHeld {
            isNextInstallHeld = false
            await withCheckedContinuation { continuation in
                heldInstall = continuation
                for waiter in installHoldWaiters {
                    waiter.resume()
                }
                installHoldWaiters.removeAll()
            }
        }
        if let installFailure {
            throw installFailure
        }
        installed = tunnel.id
    }

    public func start() async throws(ConnectionFailure) {
        operations.append(.start)
        status = .connecting
    }

    public func stop() async {
        operations.append(.stop)
        status = .disconnected
    }

    public nonisolated func emit(_ statuses: SystemConnectionStatus...) {
        for status in statuses {
            updatesContinuation.yield(status)
        }
    }

    public func holdNextInstall() {
        isNextInstallHeld = true
    }

    public func waitUntilInstallIsHeld() async {
        guard heldInstall == nil else { return }
        await withCheckedContinuation { continuation in installHoldWaiters.append(continuation) }
    }

    public func releaseHeldInstall() {
        heldInstall?.resume()
        heldInstall = nil
    }
}
