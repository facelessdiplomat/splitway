public protocol NetworkPathMonitor: Sendable {
    func pathUpdates() -> AsyncStream<NetworkPathStatus>
}
