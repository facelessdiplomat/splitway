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
    func namesTheServicesRoutedThroughTheTunnelAndSkipsUnknownOnes() async throws {
        let telegram = try ServiceIdentifier("telegram")
        let youtube = try ServiceIdentifier("youtube")
        let environment = TunnelListTestEnvironment(serviceNames: [telegram: "Telegram", youtube: "YouTube"])
        let selection = ServiceSelection([youtube, try ServiceIdentifier("custom-removed"), telegram])
        try await environment.storeTunnel(
            named: "Phone",
            routingPolicy: RoutingPolicy(mode: .selectedServices(selection))
        )

        await environment.model.load()

        #expect(environment.model.rows.map(\.routedServiceNames) == [["Telegram", "YouTube"]])
    }

    @Test
    func namesNoApplicationsWhenTheTunnelTakesAllTraffic() async throws {
        let environment = TunnelListTestEnvironment()
        try await environment.storeTunnel(named: "Office")

        await environment.model.load()

        #expect(environment.model.rows.map(\.routedApplicationNames) == [[]])
    }
}
