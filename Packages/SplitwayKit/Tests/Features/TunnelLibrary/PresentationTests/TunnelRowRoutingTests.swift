import AppRouting
import Testing
import TunnelLibraryPresentation

@MainActor
@Suite
struct TunnelRowRoutingTests {
    @Test
    func namesTheApplicationsRoutedThroughTheTunnelByName() async throws {
        let environment = TunnelListTestEnvironment()
        let selection = ApplicationSelection([
            try ApplicationIdentity(kind: .application, displayName: "Zed", path: "/Applications/Zed.app"),
            try ApplicationIdentity(kind: .commandLineTool, displayName: "curl", path: "/usr/bin/curl"),
        ])
        try await environment.storeTunnel(
            named: "Office",
            routingPolicy: RoutingPolicy(mode: .selectedApplications(selection))
        )

        await environment.model.load()

        #expect(environment.model.rows.map(\.routedApplicationNames) == [["curl", "Zed"]])
    }

    @Test
    func namesNoApplicationsWhenTheTunnelTakesAllTraffic() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")

        await environment.model.load()

        #expect(environment.model.rows.map(\.routedApplicationNames) == [[]])
    }
}
