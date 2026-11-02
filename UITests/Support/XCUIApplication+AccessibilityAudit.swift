import XCTest

extension XCUIApplication {
    func auditAccessibility(ofSheet isSheet: Bool = false, file: StaticString = #filePath, line: UInt = #line) throws {
        let systemBars =
            navigationBars.allElementsBoundByIndex + toolbars.allElementsBoundByIndex
            + searchFields.allElementsBoundByIndex
        try performAccessibilityAudit { issue in
            guard let element = issue.element else {
                if !isSheet {
                    XCTFail(
                        "\(issue.compactDescription): no element. \(issue.detailedDescription)", file: file, line: line)
                }
                return true
            }
            if systemBars.contains(where: { bar in bar.frame.contains(element.frame) }) {
                return true
            }
            let description = "\(element.elementType) \"\(element.label)\""
            XCTFail("\(issue.compactDescription): \(description). \(issue.detailedDescription)", file: file, line: line)
            return true
        }
        try failOnUntranslatedText(file: file, line: line)
    }

    private func failOnUntranslatedText(file: StaticString, line: UInt) throws {
        let labels = Self.labels(in: try snapshot())
        for label in Set(labels) where LocalizedLabels.isUntranslatedEnglish(label) {
            XCTFail("Untranslated text \"\(label)\" in \(LocalizedLabels.language)", file: file, line: line)
        }
    }

    private static func labels(in node: any XCUIElementSnapshot) -> [String] {
        [node.label] + node.children.flatMap(labels)
    }
}
