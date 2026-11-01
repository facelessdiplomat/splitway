import XCTest

extension XCUIApplication {
    private static let controlCenterSwipeStart = CGVector(dx: 0.9, dy: 0.005)
    private static let controlCenterSwipeEnd = CGVector(dx: 0.9, dy: 0.6)
    private static let nextPageSwipeStart = CGVector(dx: 0.5, dy: 0.8)
    private static let nextPageSwipeEnd = CGVector(dx: 0.5, dy: 0.2)
    private static let swipeDuration: TimeInterval = 0.1

    static var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }

    func openControlCenter() {
        coordinate(withNormalizedOffset: Self.controlCenterSwipeStart).press(
            forDuration: Self.swipeDuration,
            thenDragTo: coordinate(withNormalizedOffset: Self.controlCenterSwipeEnd)
        )
    }

    func showNextControlCenterPage() {
        coordinate(withNormalizedOffset: Self.nextPageSwipeStart).press(
            forDuration: Self.swipeDuration,
            thenDragTo: coordinate(withNormalizedOffset: Self.nextPageSwipeEnd)
        )
    }

    func waitForElement(matching predicate: NSPredicate, timeout: TimeInterval) -> Bool {
        descendants(matching: .any).matching(predicate).firstMatch.waitForExistence(timeout: timeout)
    }

    func visibleElements(where isWanted: (any XCUIElementSnapshot) -> Bool) -> [any XCUIElementSnapshot] {
        guard let tree = try? snapshot() else { return [] }
        return Self.descendants(of: tree).filter { node in
            node.elementType != .icon && !node.frame.isEmpty && frame.contains(node.frame) && isWanted(node)
        }
    }

    func tap(_ node: any XCUIElementSnapshot) {
        coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: node.frame.midX, dy: node.frame.midY))
            .tap()
    }

    func accessibilityOutline() -> String {
        guard let tree = try? snapshot() else { return "" }
        return Self.descendants(of: tree)
            .filter { node in !node.label.isEmpty || !node.identifier.isEmpty }
            .map { node in
                "\(node.elementType.rawValue) label=\(node.label) id=\(node.identifier) "
                    + "value=\(String(describing: node.value)) frame=\(node.frame)"
            }
            .joined(separator: "\n")
    }

    private static func descendants(of node: any XCUIElementSnapshot) -> [any XCUIElementSnapshot] {
        [node] + node.children.flatMap(descendants)
    }
}
