import AppRouting
import AppRoutingPresentation
import Testing

@MainActor
@Suite
struct RoutingSectionModelTests {
    @Test
    func offersAllTrafficAndSelectedApplications() {
        let model = RoutingSectionModel(policy: .default)

        #expect(model.availableModes == [.allTraffic, .selectedApplications])
    }

    @Test
    func warnsAboutAnEmptySelection() {
        let model = RoutingSectionModel(policy: .default)

        model.selectMode(.selectedApplications)

        #expect(model.warnings == [.emptyApplicationSelection])
        #expect(model.policy.mode == .selectedApplications(ApplicationSelection([])))
    }

    @Test
    func keepsTheSelectionWhenSwitchingModesBackAndForth() throws {
        let safari = try ApplicationIdentity(
            kind: .application,
            displayName: "Safari",
            path: "/Applications/Safari.app"
        )
        let selection = ApplicationSelection([safari])
        let model = RoutingSectionModel(policy: RoutingPolicy(mode: .selectedApplications(selection)))

        model.selectMode(.allTraffic)
        model.selectMode(.selectedApplications)

        #expect(model.policy.mode == .selectedApplications(selection))
        #expect(model.selectedApplicationCount == 1)
    }

    @Test
    func blocksTrafficWhenTheTunnelIsUnavailableByDefault() {
        let model = RoutingSectionModel(policy: .default)
        #expect(model.blocksWhenTunnelUnavailable)

        model.setBlocksWhenTunnelUnavailable(false)

        #expect(model.policy.whenTunnelUnavailable == .bypass)
    }

    @Test
    func replacesTheSelectedApplications() throws {
        let model = RoutingSectionModel(policy: .default)
        model.selectMode(.selectedApplications)
        let selection = try Self.safariSelection()

        model.setApplications(selection)

        #expect(model.policy.mode == .selectedApplications(selection))
        #expect(model.applicationSelection == selection)
    }

    @Test
    func usesApplicationsChosenEarlierWhenTheirModeIsSelected() throws {
        let model = RoutingSectionModel(policy: .default)
        let selection = try Self.safariSelection()
        model.setApplications(selection)

        model.selectMode(.selectedApplications)

        #expect(model.policy.mode == .selectedApplications(selection))
    }

    @Test
    func offersTheApplicationsOfATunnelSavedWhileRoutingAllTraffic() throws {
        let selection = try Self.safariSelection()
        let saved = RoutingPolicy(mode: .selectedApplications(selection)).switchingMode(to: .allTraffic)
        let model = RoutingSectionModel(policy: saved)

        model.selectMode(.selectedApplications)

        #expect(model.policy.mode == .selectedApplications(selection))
        #expect(model.selectedApplicationCount == 1)
    }

    @Test
    func keepsTheApplicationsInThePolicyWhenAllTrafficIsChosen() throws {
        let selection = try Self.safariSelection()
        let model = RoutingSectionModel(policy: RoutingPolicy(mode: .selectedApplications(selection)))

        model.selectMode(.allTraffic)

        #expect(model.policy.mode == .allTraffic)
        #expect(model.policy.applicationSelection == selection)
    }

    @Test
    func keepsTheApplicationsWhenWhatToDoWithoutTheTunnelChanges() throws {
        let selection = try Self.safariSelection()
        let saved = RoutingPolicy(mode: .selectedApplications(selection)).switchingMode(to: .allTraffic)
        let model = RoutingSectionModel(policy: saved)

        model.setBlocksWhenTunnelUnavailable(false)

        #expect(model.policy.applicationSelection == selection)
    }

    private static func safariSelection() throws -> ApplicationSelection {
        ApplicationSelection([
            try ApplicationIdentity(kind: .application, displayName: "Safari", path: "/Applications/Safari.app")
        ])
    }
}
