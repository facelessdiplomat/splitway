import XCTest

final class LiveServiceRoutingTests: XCTestCase {
    private static let connectionTimeout: TimeInterval = 30
    private static let defaultTunnelName = "cz-prg"
    private static let selectedService = "https://api.ipify.org"
    private static let otherService = "https://icanhazip.com"
    private static let loadAddress = "https://proof.ovh.net/files/100Mb.dat"
    private static let loadStreamCount = 2
    private static let requestTimeout: TimeInterval = 15
    private static let loadTimeout: TimeInterval = 300
    private static let recoveryDeadline: TimeInterval = 120

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL"] == "YES",
            "Runs only on a device that has the test tunnel"
        )
        continueAfterFailure = true
    }

    @MainActor
    func testSelectedDomainsUseTheTunnelAndOtherDomainsStayDirect() async throws {
        let application = SplitwayLaunch.applicationWithStoredTunnels()
        let connectionSwitch = Self.disconnectedSwitch(in: application)
        let directSelected = try await Self.text(at: Self.selectedService)
        let directOther = try await Self.text(at: Self.otherService)

        connectionSwitch.tap()
        XCTAssertTrue(application.staticTexts["Connected"].waitForExistence(timeout: Self.connectionTimeout))
        let selectedUsesTheTunnel = try await Self.text(at: Self.selectedService) != directSelected
        let otherStaysDirect = try await Self.text(at: Self.otherService) == directOther
        let load = try await Self.parallelDownload()
        connectionSwitch.tap()
        XCTAssertTrue(application.staticTexts["Disconnected"].waitForExistence(timeout: Self.connectionTimeout))
        let recovery = await Self.recovery(of: Self.selectedService, expecting: directSelected)

        Self.keep(
            "selected-through-tunnel=\(selectedUsesTheTunnel) other-direct=\(otherStaysDirect)"
                + " load-bytes=\(load.bytes) load-seconds=\(String(format: "%.2f", load.seconds)) recovery=\(recovery)"
        )
        XCTAssertTrue(selectedUsesTheTunnel, "The selected domain did not go through the tunnel")
        XCTAssertTrue(otherStaysDirect, "Another domain went through the tunnel")
    }

    @MainActor
    private static func disconnectedSwitch(in application: XCUIApplication) -> XCUIElement {
        let tunnelName = ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL_NAME"] ?? defaultTunnelName
        application.tapText(startingWith: tunnelName)
        let connectionSwitch = application.switches["Connection"].switches.firstMatch
        XCTAssertTrue(connectionSwitch.waitForExistence(timeout: connectionTimeout))
        if application.staticTexts["Connected"].exists {
            connectionSwitch.tap()
            XCTAssertTrue(application.staticTexts["Disconnected"].waitForExistence(timeout: connectionTimeout))
        }
        return connectionSwitch
    }

    private static func text(at address: String) async throws -> String {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: try XCTUnwrap(URL(string: address)))
        request.timeoutInterval = requestTimeout
        let (data, _) = try await session.data(for: request)
        return String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func parallelDownload() async throws -> (bytes: Int, seconds: Double) {
        let address = try XCTUnwrap(URL(string: loadAddress))
        let started = Date()
        let bytes = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<loadStreamCount {
                group.addTask {
                    let configuration = URLSessionConfiguration.ephemeral
                    configuration.timeoutIntervalForResource = loadTimeout
                    let session = URLSession(configuration: configuration)
                    defer { session.invalidateAndCancel() }
                    let (data, _) = try await session.data(from: address)
                    return data.count
                }
            }
            return try await group.reduce(0, +)
        }
        return (bytes, Date().timeIntervalSince(started))
    }

    private static func recovery(of address: String, expecting directAddress: String) async -> String {
        let started = Date()
        var attempts = 0
        while Date().timeIntervalSince(started) < recoveryDeadline {
            attempts += 1
            if let text = try? await text(at: address), text == directAddress {
                return "direct-after-\(String(format: "%.1f", Date().timeIntervalSince(started)))s-attempts-\(attempts)"
            }
            try? await Task.sleep(for: .seconds(1))
        }
        return "not-direct-within-\(Int(recoveryDeadline))s"
    }

    @MainActor
    private static func keep(_ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = "SP-4 results"
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "SP-4 results") { activity in activity.add(attachment) }
    }
}
