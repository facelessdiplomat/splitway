import TunnelLibrary

public protocol SystemTunnelController: Sendable {
    func installedTunnel() async -> TunnelIdentifier?
    func currentStatus() async -> SystemConnectionStatus
    func statusUpdates() -> AsyncStream<SystemConnectionStatus>
    func lastDisconnectFailure() async -> ConnectionFailure?
    func install(_ tunnel: Tunnel) async throws(ConnectionFailure)
    func start() async throws(ConnectionFailure)
    func stop() async
}
