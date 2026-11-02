import XCTest

final class LiveBenchmarkTests: XCTestCase {
    private static let connectionTimeout: TimeInterval = 30
    private static let routeTimeout: TimeInterval = 30
    private static let executionAllowance: TimeInterval = 1_800
    private static let defaultTunnelName = "cz-prg"
    private static let benchmarkTunnelName = "Splitway benchmark"
    private static let benchmarkServiceName = "Benchmark"
    private static let benchmarkCatalogServices = ["GitHub"]
    private static let benchmarkDomains = ["proof.ovh.net", "api.ipify.org"]
    private static let officialClientBundleIdentifier = "com.wireguard.ios"
    private static let rounds = 2

    private static var tunnelName: String {
        ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL_NAME"] ?? defaultTunnelName
    }

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SPLITWAY_LIVE_BENCHMARK"] == "YES",
            "Runs only on a device with the test tunnel in Splitway and in the official WireGuard app"
        )
        continueAfterFailure = false
        executionTimeAllowance = Self.executionAllowance
    }

    @MainActor
    func testComparesSplitwayWithTheOfficialClient() async throws {
        let splitway = SplitwayLaunch.applicationWithStoredTunnels()
        splitway.disconnectEveryTunnel()
        let direct = try await ExternalAddressProbe.currentAddress()
        var lines: [String] = []

        for round in 1...Self.rounds {
            lines.append(try await Self.measureFullTunnel(in: splitway, round: round, direct: direct))
            lines.append(try await Self.measureOfficialClient(round: round, direct: direct))
        }
        lines.append(try await Self.measureSelectedServices(in: splitway, direct: direct))
        Self.keep(lines.joined(separator: "\n"))

        XCTAssertFalse(lines.contains { line in line.contains("tunneled=false") }, "A measurement bypassed the tunnel")
    }

    @MainActor
    private static func measureFullTunnel(in application: XCUIApplication, round: Int, direct: String) async throws
        -> String
    {
        application.activate()
        application.returnToTunnelList()
        application.tapText(startingWith: tunnelName)
        application.routeAllTraffic()
        let connectionSwitch = application.switches["Connection"].switches.firstMatch
        XCTAssertTrue(connectionSwitch.waitForExistence(timeout: connectionTimeout))
        connectionSwitch.tap()
        XCTAssertTrue(application.staticTexts["Connected"].waitForExistence(timeout: connectionTimeout))
        let tunneled = await isTunneled(comparedWith: direct)
        let sample = await ThroughputSample.measure()
        connectionSwitch.tap()
        XCTAssertTrue(application.staticTexts["Disconnected"].waitForExistence(timeout: connectionTimeout))
        return sample.summary(labelled: "splitway-full-\(round) tunneled=\(tunneled)")
    }

    @MainActor
    private static func measureOfficialClient(round: Int, direct: String) async throws -> String {
        let client = XCUIApplication(bundleIdentifier: officialClientBundleIdentifier)
        client.activate()
        let toggle = client.cells.containing(.staticText, identifier: tunnelName).switches.firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: connectionTimeout), "The official client has no \(tunnelName)")
        switchOfficialClient(toggle, on: true)
        let tunneled = await isTunneled(comparedWith: direct)
        let sample = await ThroughputSample.measure()
        switchOfficialClient(toggle, on: false)
        return sample.summary(labelled: "official-full-\(round) tunneled=\(tunneled)")
    }

    @MainActor
    private static func measureSelectedServices(in application: XCUIApplication, direct: String) async throws
        -> String
    {
        application.activate()
        application.returnToTunnelList()
        application.deleteTunnels(named: benchmarkTunnelName)
        try XCTUnwrap(application.duplicateTunnel(named: tunnelName)).tap()
        application.tapButton("Edit Tunnel")
        application.replaceText(inField: "Name", with: benchmarkTunnelName)
        application.routeSelectedServices(
            benchmarkCatalogServices, andOwnService: benchmarkServiceName, domains: benchmarkDomains)
        let connectionSwitch = application.switches["Connection"].switches.firstMatch
        connectionSwitch.tap()
        XCTAssertTrue(application.staticTexts["Connected"].waitForExistence(timeout: connectionTimeout))
        let tunneled = await isTunneled(comparedWith: direct)
        let sample = await ThroughputSample.measure()
        connectionSwitch.tap()
        XCTAssertTrue(application.staticTexts["Disconnected"].waitForExistence(timeout: connectionTimeout))
        application.deleteOwnServices(named: benchmarkServiceName)
        application.returnToTunnelList()
        application.deleteTunnels(named: benchmarkTunnelName)
        return sample.summary(labelled: "splitway-services tunneled=\(tunneled)")
    }

    private static func switchOfficialClient(_ toggle: XCUIElement, on: Bool) {
        if (toggle.value as? String == "1") != on {
            toggle.tap()
        }
        let expectedValue = NSPredicate(format: "value == %@", on ? "1" : "0")
        let switched = XCTNSPredicateExpectation(predicate: expectedValue, object: toggle)
        XCTAssertEqual(XCTWaiter().wait(for: [switched], timeout: connectionTimeout), .completed)
    }

    @MainActor
    private static func isTunneled(comparedWith direct: String) async -> Bool {
        let deadline = Date().addingTimeInterval(routeTimeout)
        while Date() < deadline {
            if let address = try? await ExternalAddressProbe.currentAddress(), address != direct {
                return true
            }
            try? await Task.sleep(for: .seconds(1))
        }
        return false
    }

    private static func keep(_ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = "Live benchmark"
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Live benchmark") { activity in activity.add(attachment) }
    }
}
