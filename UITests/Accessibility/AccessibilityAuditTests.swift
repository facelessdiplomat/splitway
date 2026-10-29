import XCTest

final class AccessibilityAuditTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    @MainActor
    func testOnboardingPassesTheAccessibilityAudit() throws {
        let application = SplitwayLaunch.application(hasCompletedOnboarding: false)

        application.waitForText("Welcome to Splitway")
        try application.auditAccessibility()
        application.tapButton("Continue")
        application.waitForText("Your data stays with you")
        try application.auditAccessibility()
        application.tapButton("Continue")
        application.waitForText("What the system will ask")
        try application.auditAccessibility()
    }

    @MainActor
    func testEmptyTunnelListPassesTheAccessibilityAudit() throws {
        let application = SplitwayLaunch.application()

        application.waitForText("No tunnels yet")
        try application.auditAccessibility()
    }

    @MainActor
    func testTunnelEditorPassesTheAccessibilityAudit() throws {
        let application = SplitwayLaunch.application()

        application.addTunnel(by: "Create from scratch")
        application.waitForText("Name")
        try application.auditAccessibility(ofSheet: true)
    }

    @MainActor
    func testTunnelListAndDetailsPassTheAccessibilityAudit() throws {
        let application = SplitwayLaunch.application()
        application.addTunnel(by: "Create from scratch")
        application.scrollToButton("Add peer")
        application.type(RandomKeyText.make(), intoField: "Public key")
        application.tapButton("Save")

        application.waitForText("New tunnel")
        try application.auditAccessibility()
        application.tapText(startingWith: "New tunnel")
        application.waitForButton("Edit")
        try application.auditAccessibility()
    }

    @MainActor
    func testQRScannerPassesTheAccessibilityAudit() throws {
        let application = SplitwayLaunch.application()

        application.addTunnel(by: "Scan QR code")
        application.waitForText("Scan QR Code")
        try application.auditAccessibility(ofSheet: true)
    }

    @MainActor
    func testSettingsAndLicensesPassTheAccessibilityAudit() throws {
        let application = SplitwayLaunch.application()

        application.openMoreMenu(item: "Settings")
        application.waitForButton("Open Source Licenses")
        try application.auditAccessibility(ofSheet: true)
        application.tapButton("Open Source Licenses")
        application.waitForText("ZIPFoundation")
        try application.auditAccessibility(ofSheet: true)
        application.tapButton(labelStartingWith: "Go")
        application.waitForText("Copyright 2009 The Go Authors.")
        try application.auditAccessibility(ofSheet: true)
    }

    @MainActor
    func testLogPassesTheAccessibilityAudit() throws {
        let application = SplitwayLaunch.application()

        application.openMoreMenu(item: "Log")
        application.waitForText("Splitway 0.1.0 started")
        try application.auditAccessibility(ofSheet: true)
    }
}
