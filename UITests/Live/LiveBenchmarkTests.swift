import XCTest

final class LiveBenchmarkTests: XCTestCase {
    private static let connectionTimeout: TimeInterval = 30
    private static let routeTimeout: TimeInterval = 30
    private static let executionAllowance: TimeInterval = 2_400
    private static let defaultTunnelName = "cz-prg"
    private static let benchmarkTunnelName = "Splitway benchmark"
    private static let benchmarkServiceName = "Benchmark"
    private static let benchmarkCatalogServices = ["GitHub"]
    private static let benchmarkDomains = ["proof.ovh.net", "api.ipify.org"]
    private static let officialClientBundleIdentifier = "com.wireguard.ios"
    private static let rounds = 4
    private static let activationAttempts = 2
    private static let previousTunnelTeardown = Duration.seconds(5)

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
        splitway.prepareCopy(of: Self.tunnelName, named: Self.benchmarkTunnelName)
        splitway.routeAllTraffic()
        let direct = try await ExternalAddressProbe.currentAddress()
        var lines: [String] = []

        for round in 1...Self.rounds {
            lines += await Self.measureRound(round, in: splitway, direct: direct)
        }
        lines.append(Self.keep(await Self.measureSelectedServices(in: splitway, direct: direct)))

        XCTAssertFalse(lines.contains { line in line.contains("tunneled=false") }, "A measurement bypassed the tunnel")
    }

    @MainActor
    private static func measureRound(_ round: Int, in splitway: XCUIApplication, direct: String) async -> [String] {
        if round.isMultiple(of: 2) {
            let official = keep(await measureOfficialClient(round: round, direct: direct))
            let full = keep(await measureFullTunnel(in: splitway, round: round, direct: direct))
            return [official, full]
        }
        let full = keep(await measureFullTunnel(in: splitway, round: round, direct: direct))
        let official = keep(await measureOfficialClient(round: round, direct: direct))
        return [full, official]
    }

    @MainActor
    private static func measureFullTunnel(in application: XCUIApplication, round: Int, direct: String) async
        -> String
    {
        application.activate()
        application.returnToTunnelList()
        application.tapText(startingWith: benchmarkTunnelName)
        return await measureConnection(in: application, labelled: "splitway-full-\(round)", direct: direct)
    }

    @MainActor
    private static func measureOfficialClient(round: Int, direct: String) async -> String {
        let client = XCUIApplication(bundleIdentifier: officialClientBundleIdentifier)
        let toggle = client.cells.containing(.staticText, identifier: tunnelName).switches.firstMatch
        let label = "official-full-\(round)"
        for attempt in 1...activationAttempts {
            try? await Task.sleep(for: previousTunnelTeardown)
            client.terminate()
            client.activate()
            XCTAssertTrue(toggle.waitForExistence(timeout: connectionTimeout), "The client has no \(tunnelName)")
            if toggle.value as? String != "1" {
                toggle.tap()
            }
            let isTunneled = await isTunneled(comparedWith: direct)
            var sample: ThroughputSample?
            if isTunneled {
                sample = await ThroughputSample.measure()
            } else {
                keepScreen(named: "\(label) not tunneled, attempt \(attempt)")
            }
            dismissAlert(in: client)
            switchOfficialClient(toggle, on: false)
            if let sample {
                return sample.summary(labelled: "\(label) tunneled=true attempt=\(attempt)")
            }
        }
        return "\(label) tunneled=false"
    }

    @MainActor
    private static func measureSelectedServices(in application: XCUIApplication, direct: String) async -> String {
        application.activate()
        application.returnToTunnelList()
        application.tapText(startingWith: benchmarkTunnelName)
        application.tapButton("Edit Tunnel")
        application.routeSelectedServices(
            benchmarkCatalogServices, andOwnService: benchmarkServiceName, domains: benchmarkDomains)
        let line = await measureConnection(in: application, labelled: "splitway-services", direct: direct)
        application.deleteOwnServices(named: benchmarkServiceName)
        application.returnToTunnelList()
        application.deleteTunnels(named: benchmarkTunnelName)
        return line
    }

    @MainActor
    private static func measureConnection(in application: XCUIApplication, labelled label: String, direct: String)
        async -> String
    {
        let connectionSwitch = application.switches["Connection"].switches.firstMatch
        XCTAssertTrue(connectionSwitch.waitForExistence(timeout: connectionTimeout))
        for attempt in 1...activationAttempts {
            connectionSwitch.tap()
            XCTAssertTrue(application.staticTexts["Connected"].waitForExistence(timeout: connectionTimeout))
            let isTunneled = await isTunneled(comparedWith: direct)
            var sample: ThroughputSample?
            if isTunneled {
                sample = await ThroughputSample.measure()
            } else {
                keepScreen(named: "\(label) not tunneled, attempt \(attempt)")
            }
            connectionSwitch.tap()
            XCTAssertTrue(application.staticTexts["Disconnected"].waitForExistence(timeout: connectionTimeout))
            if let sample {
                return sample.summary(labelled: "\(label) tunneled=true attempt=\(attempt)")
            }
        }
        return "\(label) tunneled=false"
    }

    @MainActor
    private static func dismissAlert(in application: XCUIApplication) {
        let alert = application.alerts.firstMatch
        if alert.exists {
            alert.buttons.firstMatch.tap()
        }
    }

    @MainActor
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

    @MainActor
    private static func keep(_ line: String) -> String {
        let attachment = XCTAttachment(string: line)
        attachment.name = "Live benchmark"
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Live benchmark") { activity in activity.add(attachment) }
        return line
    }

    @MainActor
    private static func keepScreen(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: name) { activity in activity.add(attachment) }
    }
}
