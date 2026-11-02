import XCTest

final class KeyboardShortcutTests: XCTestCase {
    private static let elementTimeout: TimeInterval = 5
    private static let defaultTunnelName = "New tunnel"
    private static let duplicateSuffix = " 2"

    override func setUpWithError() throws {
        try XCTSkipUnless(
            UIDevice.current.userInterfaceIdiom == .pad,
            "Hardware keyboard shortcuts are checked on iPad"
        )
        continueAfterFailure = false
    }

    @MainActor
    func testReachesTheTunnelActionsFromTheKeyboard() {
        let application = SplitwayLaunch.application()
        let tunnelName = LocalizedLabels.matching(Self.defaultTunnelName).first ?? Self.defaultTunnelName
        let duplicateName = tunnelName + Self.duplicateSuffix
        application.waitForText("No tunnels yet")

        application.typeKey("o", modifierFlags: [.command, .shift])
        Self.close("Cancel", in: application, opened: "⇧⌘O did not open the file picker")
        application.typeKey("n", modifierFlags: .command)
        application.scrollToButton("Add peer")
        application.type(RandomKeyText.make(), intoField: "Public key")
        application.typeKey("s", modifierFlags: .command)
        application.tapText(startingWith: tunnelName)
        application.typeKey("d", modifierFlags: .command)
        application.waitForText(duplicateName)

        application.typeKey("e", modifierFlags: .command)
        let nameField = application.textFields.matching(LocalizedLabels.predicate("Name")).firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: Self.elementTimeout), "⌘E did not open the editor")
        XCTAssertEqual(nameField.value as? String, tunnelName)
        Self.close("Cancel", in: application, opened: "The editor has no Cancel button")

        application.typeKey(",", modifierFlags: .command)
        application.waitForButton("Open Source Licenses")
        Self.close("Close", in: application, opened: "⌘, did not open Settings")

        application.typeKey("l", modifierFlags: [.command, .option])
        application.waitForText("Splitway 0.1.0 started")
        Self.close("Close", in: application, opened: "⌥⌘L did not open the log")

        application.typeKey("f", modifierFlags: .command)
        application.typeText("2")
        let originalRow = application.switches[tunnelName].firstMatch
        XCTAssertTrue(originalRow.waitForNonExistence(timeout: Self.elementTimeout), "⌘F did not search")
        XCTAssertTrue(application.switches[duplicateName].firstMatch.exists, "The search hid the match")
    }

    @MainActor
    private static func close(_ englishLabel: String, in application: XCUIApplication, opened failure: String) {
        let button = application.buttons.matching(LocalizedLabels.predicate(englishLabel)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: elementTimeout), failure)
        button.tap()
        XCTAssertTrue(button.waitForNonExistence(timeout: elementTimeout), "\(button) stayed on screen")
    }
}
