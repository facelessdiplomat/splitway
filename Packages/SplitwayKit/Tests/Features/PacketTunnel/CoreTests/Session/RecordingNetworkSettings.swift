import PacketTunnel

final class RecordingNetworkSettings: NetworkSettingsApplier {
    private(set) var appliedPlans: [TunnelNetworkPlan] = []
    private let failure: PacketTunnelError?

    init(failure: PacketTunnelError? = nil) {
        self.failure = failure
    }

    nonisolated(nonsending) func apply(_ plan: TunnelNetworkPlan) async throws(PacketTunnelError) {
        if let failure {
            throw failure
        }
        appliedPlans.append(plan)
    }
}
