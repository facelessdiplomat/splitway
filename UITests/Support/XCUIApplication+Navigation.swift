import XCTest

extension XCUIApplication {
    private static let elementTimeout: TimeInterval = 5
    private static let maximumScrolls = 6

    func tapButton(_ label: String) {
        let button = buttons.matching(LocalizedLabels.predicate(label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: Self.elementTimeout), "No button \(label)")
        button.tap()
    }

    func scrollToButton(_ label: String) {
        let button = buttons.matching(LocalizedLabels.predicate(label)).firstMatch
        var scrolls = 0
        while !button.exists, scrolls < Self.maximumScrolls {
            swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(button.waitForExistence(timeout: Self.elementTimeout), "No button \(label) after scrolling")
        button.tap()
    }

    func tapButton(labelStartingWith prefix: String) {
        let button = buttons.matching(LocalizedLabels.prefixPredicate(prefix)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: Self.elementTimeout), "No button starting with \(prefix)")
        button.tap()
    }

    func tapText(startingWith prefix: String) {
        let text = staticTexts.matching(LocalizedLabels.prefixPredicate(prefix)).firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: Self.elementTimeout), "No text starting with \(prefix)")
        text.tap()
    }

    func type(_ text: String, intoField label: String) {
        let field = textFields.matching(LocalizedLabels.predicate(label)).firstMatch
        var scrolls = 0
        while !field.exists, scrolls < Self.maximumScrolls {
            swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(field.waitForExistence(timeout: Self.elementTimeout), "No field \(label)")
        field.tap()
        field.typeText(text + XCUIKeyboardKey.return.rawValue)
    }

    func addTunnel(by method: String) {
        tapButton("Add tunnel")
        tapButton(method)
    }

    func tapSecondaryAction(_ item: String, inNavigationBar title: String) {
        let bar = navigationBars.matching(LocalizedLabels.predicate(title)).firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: Self.elementTimeout), "No navigation bar \(title)")
        let more = bar.buttons.matching(LocalizedLabels.predicate("More")).firstMatch
        if more.exists {
            more.tap()
        }
        tapButton(item)
    }

    func openMoreMenu(item: String) {
        tapButton("More")
        tapButton(item)
    }

    func waitForButton(_ label: String) {
        let button = buttons.matching(LocalizedLabels.predicate(label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: Self.elementTimeout), "No button \(label)")
    }

    func waitForText(_ text: String) {
        let element = staticTexts.matching(LocalizedLabels.predicate(text)).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: Self.elementTimeout), "No text \(text)")
    }

    func waitForText(counting count: Int, in format: String) {
        let labels = LocalizedLabels.counted(format, count: count)
        let element = staticTexts.matching(NSPredicate(format: "label IN %@", labels)).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: Self.elementTimeout), "No text \(labels)")
    }
}
