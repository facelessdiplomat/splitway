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
    }
}
