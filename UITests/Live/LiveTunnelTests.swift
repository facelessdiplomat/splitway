import XCTest

final class LiveTunnelTests: XCTestCase {
    private static let connectionTimeout: TimeInterval = 30
    private static let defaultTunnelName = "cz-prg"

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL"] == "YES",
            "Runs only on a device that has the test tunnel"
        )
        continueAfterFailure = false
    }

    @MainActor
    func testFullTunnelChangesTheExternalAddressAndDisconnects() async throws {
        let tunnelName = ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL_NAME"] ?? Self.defaultTunnelName
        let application = SplitwayLaunch.applicationWithStoredTunnels()
        application.tapText(startingWith: tunnelName)
        application.routeAllTraffic()
        let connectionSwitch = application.switches["Connection"].switches.firstMatch
        let connected = application.staticTexts["Connected"]
        let disconnected = application.staticTexts["Disconnected"]
        XCTAssertTrue(connectionSwitch.waitForExistence(timeout: Self.connectionTimeout))
        if connected.exists {
            connectionSwitch.tap()
            XCTAssertTrue(disconnected.waitForExistence(timeout: Self.connectionTimeout))
        }
        let addressWithoutTunnel = try await ExternalAddressProbe.currentAddress()

        connectionSwitch.tap()
        XCTAssertTrue(connected.waitForExistence(timeout: Self.connectionTimeout))
        let addressThroughTunnel = try await ExternalAddressProbe.currentAddress()
        connectionSwitch.tap()

        XCTAssertTrue(disconnected.waitForExistence(timeout: Self.connectionTimeout))
        XCTAssertTrue(addressThroughTunnel != addressWithoutTunnel, "The external address stayed the same")
    }
}
