import PacketTunnel
import Synchronization

final class FakeTunnelNetworkSettingsApplier: TunnelNetworkSettingsApplier {
    private let log: SessionEventLog
    private let rejectsSettings: Bool
    private let appliedPlans = Mutex<[TunnelNetworkPlan]>([])

    init(log: SessionEventLog, rejectsSettings: Bool) {
        self.log = log
        self.rejectsSettings = rejectsSettings
    }

    var plans: [TunnelNetworkPlan] {
        appliedPlans.withLock { plans in plans }
    }

    func apply(_ plan: TunnelNetworkPlan) async throws(TunnelNetworkSettingsError) {
        guard !rejectsSettings else { throw .rejected }
        appliedPlans.withLock { plans in plans.append(plan) }
        log.record(.appliedSettings)
    }
}
