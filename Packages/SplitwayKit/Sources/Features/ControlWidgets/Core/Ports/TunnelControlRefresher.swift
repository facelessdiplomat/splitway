public protocol TunnelControlRefresher: Sendable {
    func refresh() async
}
