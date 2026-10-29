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
    func warnsAboutEmptySelections() {
        let noApplications = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([])))
        let noServices = RoutingPolicy(mode: .selectedServices(ServiceSelection([])))

        #expect(noApplications.warnings == [.emptyApplicationSelection])
        #expect(noServices.warnings == [.emptyServiceSelection])
        #expect(RoutingPolicy.default.warnings.isEmpty)
    }

    @Test
    func keepsModesThePlatformSupports() throws {
        let applications = RoutingPolicy(mode: .selectedApplications(ApplicationSelection([try sampleApplication()])))
        let services = RoutingPolicy(mode: .selectedServices(ServiceSelection([try ServiceIdentifier("telegram")])))

        #expect(applications.resolved(on: .macOS) == ResolvedRoutingPolicy(policy: applications, unsupportedMode: nil))
        #expect(services.resolved(on: .iOS) == ResolvedRoutingPolicy(policy: services, unsupportedMode: nil))
        #expect(RoutingPolicy.default.resolved(on: .iOS).unsupportedMode == nil)
    }

    @Test
    func fallsBackToAllTrafficWhenThePlatformLacksTheMode() throws {
        let applications = RoutingPolicy(
            mode: .selectedApplications(ApplicationSelection([try sampleApplication()])),
            whenTunnelUnavailable: .bypass
        )

        let resolved = applications.resolved(on: .iOS)

        #expect(resolved.policy == RoutingPolicy(mode: .allTraffic, whenTunnelUnavailable: .bypass))
        #expect(resolved.unsupportedMode == .selectedApplications)
    }

    private func sampleApplication() throws -> ApplicationIdentity {
        try ApplicationIdentity(kind: .application, displayName: "Safari", path: "/Applications/Safari.app")
    }
}
