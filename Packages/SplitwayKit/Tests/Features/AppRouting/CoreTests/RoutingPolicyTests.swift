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
    func warnsAboutAnEmptyServiceSelection() {
        let noServices = RoutingPolicy(mode: .selectedServices(ServiceSelection([])))

        #expect(noServices.warnings == [.emptyServiceSelection])
    }

    @Test
    func remembersTheServicesWhileAnotherModeIsChosen() throws {
        let selection = ServiceSelection([try ServiceIdentifier("telegram")])

        let allTraffic = RoutingPolicy(mode: .selectedServices(selection)).switchingMode(to: .allTraffic)

        #expect(allTraffic.mode == .allTraffic)
        #expect(allTraffic.switchingMode(to: .selectedServices).mode == .selectedServices(selection))
    }

    @Test
    func replacesTheServicesWithoutChangingTheMode() throws {
        let selection = ServiceSelection([try ServiceIdentifier("telegram")])

        let policy = RoutingPolicy.default.replacingServiceSelection(with: selection)

        #expect(policy.mode == .allTraffic)
        #expect(policy.serviceSelection == selection)
    }

    @Test
    func keepsTheApplicationsWhenTheServicesChange() throws {
        let applications = ApplicationSelection([try sampleApplication()])
        let policy = RoutingPolicy(mode: .selectedApplications(applications))

        let changed = policy.replacingServiceSelection(with: ServiceSelection([try ServiceIdentifier("telegram")]))

        #expect(changed.mode == .selectedApplications(applications))
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
