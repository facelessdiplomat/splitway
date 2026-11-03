import AppRouting
import Testing

@Suite
struct RoutingPolicyTests {
    @Test
    func routesAllTrafficAndBlocksWhenTheTunnelIsUnavailableByDefault() {
        #expect(RoutingPolicy.default.mode == .allTraffic)
        #expect(RoutingPolicy.default.whenTunnelUnavailable == .block)
    }

    @Test
    func warnsAboutAnEmptyApplicationSelection() {
        let noApplications = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([])))

        #expect(noApplications.warnings == [.emptyApplicationSelection])
        #expect(RoutingPolicy.default.warnings.isEmpty)
    }

    @Test
    func remembersTheApplicationsWhileAnotherModeIsChosen() throws {
        let selection = ApplicationSelection([try sampleApplication()])

        let allTraffic = RoutingPolicy(mode: .selectedApplications(selection)).switchingMode(to: .allTraffic)

        #expect(allTraffic.mode == .allTraffic)
        #expect(allTraffic.switchingMode(to: .selectedApplications).mode == .selectedApplications(selection))
    }

    @Test
    func keepsWhatToDoWithoutTheTunnelWhenTheModeChanges() {
        let policy = RoutingPolicy(mode: .allTraffic, whenTunnelUnavailable: .bypass)

        let applications = policy.switchingMode(to: .selectedApplications)

        #expect(applications.whenTunnelUnavailable == .bypass)
    }

    @Test
    func replacesTheApplicationsWithoutChangingTheMode() throws {
        let selection = ApplicationSelection([try sampleApplication()])

        let policy = RoutingPolicy.default.replacingApplicationSelection(with: selection)

        #expect(policy.mode == .allTraffic)
        #expect(policy.applicationSelection == selection)
    }

    @Test
    func keepsTheSelectionsWhenWhatToDoWithoutTheTunnelChanges() throws {
        let selection = ApplicationSelection([try sampleApplication()])
        let policy = RoutingPolicy(mode: .selectedApplications(selection)).switchingMode(to: .allTraffic)

        let bypassing = policy.replacingTunnelUnavailableBehavior(with: .bypass)

        #expect(bypassing.whenTunnelUnavailable == .bypass)
        #expect(bypassing.applicationSelection == selection)
    }

    private func sampleApplication() throws -> ApplicationIdentity {
        try ApplicationIdentity(kind: .application, displayName: "Safari", path: "/Applications/Safari.app")
    }
}
