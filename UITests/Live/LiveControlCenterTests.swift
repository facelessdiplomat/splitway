import XCTest

final class LiveControlCenterTests: XCTestCase {
    private enum Step: String {
        case connect
        case disconnect
    }

    private static let connectionTimeout: TimeInterval = 30
    private static let pageTimeout: TimeInterval = 3
    private static let controlCenterPages = 4
    private static let defaultTunnelName = "cz-prg"
    private static let controlKind = "tunnel-connection"
    private static let controlTitle = "Splitway"

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL"] == "YES",
            "Runs only on a device that has the test tunnel"
        )
        continueAfterFailure = false
    }

    @MainActor
    func testControlCenterConnectsAndDisconnectsWithoutOpeningSplitway() throws {
        let tunnelName = ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL_NAME"] ?? Self.defaultTunnelName
        let application = SplitwayLaunch.applicationWithStoredTunnels()
        application.disconnectEveryTunnel()
        let connectedSwitch = application.switches.matching(NSPredicate(format: "value == '1'")).firstMatch

        try Self.switchTunnelFromControlCenter(named: tunnelName, step: .connect)
        application.activate()
        let isConnected = connectedSwitch.waitForExistence(timeout: Self.connectionTimeout)
        Self.keepScreenshot(named: "Splitway after connecting from Control Center")
        try Self.switchTunnelFromControlCenter(named: tunnelName, step: .disconnect)
        application.activate()
        let isDisconnected = connectedSwitch.waitForNonExistence(timeout: Self.connectionTimeout)
        Self.keepScreenshot(named: "Splitway after disconnecting from Control Center")
        application.disconnectEveryTunnel()

        XCTAssertTrue(isConnected, "The control did not connect a tunnel")
        XCTAssertTrue(isDisconnected, "The control did not disconnect the tunnel")
    }

    @MainActor
    private static func switchTunnelFromControlCenter(named tunnelName: String, step: Step) throws {
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication.springboard
        springboard.openControlCenter()
        let foundControl = tunnelControl(in: springboard, tunnelName: tunnelName, step: step)
        try XCTSkipIf(
            foundControl == nil && step == .connect,
            "Add the Splitway Tunnel control to Control Center to run this test"
        )
        let control = try XCTUnwrap(foundControl, "The Splitway control left Control Center")
        keep("\(control.elementType.rawValue) \(control.label) \(control.identifier)", named: "Control for \(step)")
        springboard.tap(control)
        keepScreenshot(named: "Control Center after \(step)")
        XCUIDevice.shared.press(.home)
    }

    @MainActor
    private static func tunnelControl(
        in springboard: XCUIApplication,
        tunnelName: String,
        step: Step
    ) -> (any XCUIElementSnapshot)? {
        let predicate = NSPredicate(
            format: "identifier CONTAINS %@ OR label CONTAINS[c] %@ OR label CONTAINS[c] %@",
            controlKind, tunnelName, controlTitle
        )
        for page in 1...controlCenterPages {
            _ = springboard.waitForElement(matching: predicate, timeout: pageTimeout)
            keepScreenshot(named: "Control Center page \(page) before \(step)")
            keep(springboard.accessibilityOutline(), named: "Control Center page \(page) elements before \(step)")
            let controls = springboard.visibleElements { node in
                node.identifier.contains(controlKind) || node.label.localizedCaseInsensitiveContains(tunnelName)
                    || node.label.localizedCaseInsensitiveContains(controlTitle)
            }
            if let control = controls.first {
                return control
            }
            springboard.showNextControlCenterPage()
        }
        return nil
    }

    @MainActor
    private static func keepScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: name) { activity in activity.add(attachment) }
    }

    @MainActor
    private static func keep(_ text: String, named name: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: name) { activity in activity.add(attachment) }
    }
}
