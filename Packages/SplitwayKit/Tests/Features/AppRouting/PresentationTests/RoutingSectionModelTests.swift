import AppRouting
import AppRoutingPresentation
import Testing

@MainActor
@Suite
struct RoutingSectionModelTests {
    @Test
    func offersSelectedApplicationsOnMac() {
        let model = RoutingSectionModel(policy: .default, platform: .macOS)

        #expect(model.availableModes == [.allTraffic, .selectedApplications])
    }

    @Test
    func offersSelectedServicesOnIPhoneAndIPad() {
        let model = RoutingSectionModel(policy: .default, platform: .iOS)

        #expect(model.availableModes == [.allTraffic, .selectedServices])
    }

    @Test
    func ignoresAModeThePlatformDoesNotSupport() {
        let model = RoutingSectionModel(policy: .default, platform: .iOS)

        model.selectMode(.selectedApplications)

        #expect(model.selectedMode == .allTraffic)
    }

    @Test
    func warnsAboutAnEmptySelection() {
        let model = RoutingSectionModel(policy: .default, platform: .iOS)

        model.selectMode(.selectedServices)

        #expect(model.warnings == [.emptyServiceSelection])
        #expect(model.policy.mode == .selectedServices(ServiceSelection([])))
    }

    @Test
    func keepsTheSelectionWhenSwitchingModesBackAndForth() throws {
        let safari = try ApplicationIdentity(
            kind: .application,
            displayName: "Safari",
            path: "/Applications/Safari.app"
        )
        let selection = ApplicationSelection([safari])
        let model = RoutingSectionModel(policy: RoutingPolicy(mode: .selectedApplications(selection)), platform: .macOS)

        model.selectMode(.allTraffic)
        model.selectMode(.selectedApplications)

        #expect(model.policy.mode == .selectedApplications(selection))
        #expect(model.selectedApplicationCount == 1)
    }

    @Test
    func blocksTrafficWhenTheTunnelIsUnavailableByDefault() {
        let model = RoutingSectionModel(policy: .default, platform: .macOS)
        #expect(model.blocksWhenTunnelUnavailable)

        model.setBlocksWhenTunnelUnavailable(false)

        #expect(model.policy.whenTunnelUnavailable == .bypass)
    }

    @Test(arguments: [(RoutingPlatform.macOS, true), (.iOS, false)])
    func asksWhatToDoWithoutTheTunnelOnlyOnMac(platform: RoutingPlatform, showsChoice: Bool) {
        let model = RoutingSectionModel(policy: .default, platform: platform)

        #expect(model.offersUnavailableTunnelChoice == showsChoice)
    }

    @Test
    func replacesTheSelectedApplications() throws {
        let model = RoutingSectionModel(policy: .default, platform: .macOS)
        model.selectMode(.selectedApplications)
        let selection = try Self.safariSelection()

        model.setApplications(selection)

        #expect(model.policy.mode == .selectedApplications(selection))
        #expect(model.applicationSelection == selection)
    }

    @Test
    func usesApplicationsChosenEarlierWhenTheirModeIsSelected() throws {
        let model = RoutingSectionModel(policy: .default, platform: .macOS)
        let selection = try Self.safariSelection()
        model.setApplications(selection)

        model.selectMode(.selectedApplications)

        #expect(model.policy.mode == .selectedApplications(selection))
    }

    @Test
    func offersTheApplicationsOfATunnelSavedWhileRoutingAllTraffic() throws {
        let selection = try Self.safariSelection()
        let saved = RoutingPolicy(mode: .selectedApplications(selection)).switchingMode(to: .allTraffic)
        let model = RoutingSectionModel(policy: saved, platform: .macOS)

        model.selectMode(.selectedApplications)

        #expect(model.policy.mode == .selectedApplications(selection))
        #expect(model.selectedApplicationCount == 1)
    }

    @Test
    func keepsTheApplicationsInThePolicyWhenAllTrafficIsChosen() throws {
        let selection = try Self.safariSelection()
        let model = RoutingSectionModel(policy: RoutingPolicy(mode: .selectedApplications(selection)), platform: .macOS)

        model.selectMode(.allTraffic)

        #expect(model.policy.mode == .allTraffic)
        #expect(model.policy.applicationSelection == selection)
    }

    @Test
    func keepsTheApplicationsWhenWhatToDoWithoutTheTunnelChanges() throws {
        let selection = try Self.safariSelection()
        let saved = RoutingPolicy(mode: .selectedApplications(selection)).switchingMode(to: .allTraffic)
        let model = RoutingSectionModel(policy: saved, platform: .macOS)

        model.setBlocksWhenTunnelUnavailable(false)

        #expect(model.policy.applicationSelection == selection)
    }

    private static func safariSelection() throws -> ApplicationSelection {
        ApplicationSelection([
            try ApplicationIdentity(kind: .application, displayName: "Safari", path: "/Applications/Safari.app")
        ])
    }
}
