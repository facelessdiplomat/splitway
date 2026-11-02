import XCTest

extension XCUIApplication {
    private static let fieldTimeout: TimeInterval = 5
    private static let trailingEdge = CGVector(dx: 1, dy: 0.5)
    private static let insideTrailingEdge = CGVector(dx: -1, dy: 0)

    func replaceText(inField label: String, with text: String) {
        let field = textFields[label].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: Self.fieldTimeout), "No field \(label)")
        field.coordinate(withNormalizedOffset: Self.trailingEdge).withOffset(Self.insideTrailingEdge).tap()
        let currentText = field.value as? String ?? ""
        let deletion = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count)
        field.typeText(deletion + text + XCUIKeyboardKey.return.rawValue)
        XCTAssertEqual(field.value as? String, text, "Field \(label) kept other text")
    }

    func waitForText(startingWith prefix: String) {
        let text = staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: Self.fieldTimeout), "No text starting with \(prefix)")
    }
}
