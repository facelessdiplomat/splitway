public protocol TunnelActivityProbe: Sendable {
    func isActive(_ tunnel: TunnelIdentifier) async -> Bool
    func stop(_ tunnel: TunnelIdentifier) async throws(TunnelActivityError)
}
