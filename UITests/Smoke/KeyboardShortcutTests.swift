import XCTest

final class KeyboardShortcutTests: XCTestCase {
    private static let elementTimeout: TimeInterval = 5
    private static let tunnelName = "New tunnel"
    private static let duplicateName = "New tunnel 2"

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
        application.waitForText("No tunnels yet")

        application.typeKey("o", modifierFlags: [.command, .shift])
        Self.close(application.buttons["Cancel"].firstMatch, opened: "⇧⌘O did not open the file picker")
        application.typeKey("n", modifierFlags: .command)
        application.scrollToButton("Add peer")
        application.type(RandomKeyText.make(), intoField: "Public key")
        application.typeKey("s", modifierFlags: .command)
        application.tapText(startingWith: Self.tunnelName)
        application.typeKey("d", modifierFlags: .command)
        application.waitForText(Self.duplicateName)

        application.typeKey("e", modifierFlags: .command)
        let nameField = application.textFields["Name"].firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: Self.elementTimeout), "⌘E did not open the editor")
        XCTAssertEqual(nameField.value as? String, Self.tunnelName)
        Self.close(application.buttons["Cancel"].firstMatch, opened: "The editor has no Cancel button")

        application.typeKey(",", modifierFlags: .command)
        application.waitForButton("Open Source Licenses")
        Self.close(application.buttons["Close"].firstMatch, opened: "⌘, did not open Settings")

        application.typeKey("l", modifierFlags: [.command, .option])
        application.waitForText("Splitway 0.1.0 started")
        Self.close(application.buttons["Close"].firstMatch, opened: "⌥⌘L did not open the log")

        application.typeKey("f", modifierFlags: .command)
        application.typeText("2")
        let originalRow = application.switches[Self.tunnelName].firstMatch
        XCTAssertTrue(originalRow.waitForNonExistence(timeout: Self.elementTimeout), "⌘F did not search")
        XCTAssertTrue(application.switches[Self.duplicateName].firstMatch.exists, "The search hid the match")
    }

    @MainActor
    private static func close(_ button: XCUIElement, opened failure: String) {
        XCTAssertTrue(button.waitForExistence(timeout: elementTimeout), failure)
        button.tap()
        XCTAssertTrue(button.waitForNonExistence(timeout: elementTimeout), "\(button) stayed on screen")
    }
}
