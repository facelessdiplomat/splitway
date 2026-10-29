public protocol TunnelNetworkSettingsApplier: Sendable {
    func apply(_ plan: TunnelNetworkPlan) async throws(TunnelNetworkSettingsError)
}
