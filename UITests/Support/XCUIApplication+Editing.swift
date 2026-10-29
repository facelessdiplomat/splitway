import XCTest

extension XCUIApplication {
    private static let fieldTimeout: TimeInterval = 5
    private static let promptTimeout: TimeInterval = 5
    private static let trailingEdge = CGVector(dx: 0.98, dy: 0.5)
    private static let springboardIdentifier = "com.apple.springboard"
    private static let allowPasteLabel = "Allow Paste"

    func replaceText(inField label: String, with text: String) {
        let field = textFields[label].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: Self.fieldTimeout), "No field \(label)")
        field.coordinate(withNormalizedOffset: Self.trailingEdge).tap()
        let currentText = field.value as? String ?? ""
        let deletion = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count)
        field.typeText(deletion + text + XCUIKeyboardKey.return.rawValue)
    }

    func allowPasteIfAsked() {
        let prompt = XCUIApplication(bundleIdentifier: Self.springboardIdentifier).buttons[Self.allowPasteLabel]
        if prompt.waitForExistence(timeout: Self.promptTimeout) {
            prompt.tap()
        }
    }

    func waitForText(startingWith prefix: String) {
        let text = staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: Self.fieldTimeout), "No text starting with \(prefix)")
    }
}
