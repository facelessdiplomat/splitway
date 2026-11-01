import XCTest

extension XCUIApplication {
    private static let elementTimeout: TimeInterval = 5
    private static let maximumScrolls = 6
    private static let switchKnob = CGVector(dx: 0.94, dy: 0.5)
    private static let routingModeLabel = "Through the tunnel"

    func chooseRoutingMode(_ mode: String) {
        let picker = buttons.matching(NSPredicate(format: "label BEGINSWITH %@", Self.routingModeLabel)).firstMatch
        var scrolls = 0
        while !picker.isHittable, scrolls < Self.maximumScrolls {
            swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(picker.waitForExistence(timeout: Self.elementTimeout), "No routing mode picker")
        picker.tap()
        tapButton(mode)
    }

    func switchOn(_ label: String) {
        let toggle = switches[label].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: Self.elementTimeout), "No switch \(label)")
        toggle.coordinate(withNormalizedOffset: Self.switchKnob).tap()
        XCTAssertEqual(toggle.value as? String, "1", "Switch \(label) stayed off")
    }

    func type(_ text: String, intoTextView label: String) {
        let view = textViews[label].firstMatch
        XCTAssertTrue(view.waitForExistence(timeout: Self.elementTimeout), "No text view \(label)")
        view.tap()
        view.typeText(text)
    }

    func tapButton(_ label: String, inNavigationBar title: String) {
        let button = navigationBars[title].buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: Self.elementTimeout), "No button \(label) in \(title)")
        button.tap()
    }
}
