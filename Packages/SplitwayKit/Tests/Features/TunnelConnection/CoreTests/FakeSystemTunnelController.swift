import TunnelConnection
import TunnelLibrary

actor FakeSystemTunnelController: SystemTunnelController {
    enum Operation: Equatable {
        case install(TunnelIdentifier)
        case start
        case stop
    }

    private(set) var operations: [Operation] = []
    private(set) var status: SystemConnectionStatus
    private var installed: TunnelIdentifier?
    private let installFailure: ConnectionFailure?
    private let disconnectFailure: ConnectionFailure?
    private var isNextInstallHeld = false
    private var heldInstall: CheckedContinuation<Void, Never>?
    private var installHoldWaiters: [CheckedContinuation<Void, Never>] = []
    private let updates: AsyncStream<SystemConnectionStatus>
    private let updatesContinuation: AsyncStream<SystemConnectionStatus>.Continuation

    init(
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

    func installedTunnel() -> TunnelIdentifier? {
        installed
    }

    func currentStatus() -> SystemConnectionStatus {
        status
    }

    nonisolated func statusUpdates() -> AsyncStream<SystemConnectionStatus> {
        updates
    }

    func lastDisconnectFailure() -> ConnectionFailure? {
        disconnectFailure
    }

    func install(_ tunnel: Tunnel) async throws(ConnectionFailure) {
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

    func start() async throws(ConnectionFailure) {
        operations.append(.start)
        status = .connecting
    }

    func stop() async {
        operations.append(.stop)
        status = .disconnected
    }

    nonisolated func emit(_ statuses: SystemConnectionStatus...) {
        for status in statuses {
            updatesContinuation.yield(status)
        }
    }

    func holdNextInstall() {
        isNextInstallHeld = true
    }

    func waitUntilInstallIsHeld() async {
        guard heldInstall == nil else { return }
        await withCheckedContinuation { continuation in installHoldWaiters.append(continuation) }
    }

    func releaseHeldInstall() {
        heldInstall?.resume()
        heldInstall = nil
    }
}
