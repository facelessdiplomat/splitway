public protocol NetworkSettingsApplier {
    nonisolated(nonsending) func apply(_ plan: TunnelNetworkPlan) async throws(PacketTunnelError)
}
