import XCTest

extension XCUIApplication {
    private static let liveElementTimeout: TimeInterval = 10
    private static let contextMenuPressDuration: TimeInterval = 1.2
    private static let serviceListScrolls = 12
    private static let leftoverDeletions = 3
    private static let attemptsPerService = 3
    private static let switchKnobInset: CGFloat = 30
    private static let rowLabelInset: CGFloat = 40
    private static let scrollStart = CGVector(dx: 0.5, dy: 0.7)
    private static let scrollEnd = CGVector(dx: 0.5, dy: 0.4)
    private static let swipeActionsStart = CGVector(dx: 0.9, dy: 0.5)
    private static let swipeActionsEnd = CGVector(dx: 0.1, dy: 0.5)
    private static let scrollPressDuration: TimeInterval = 0.05
    private static let scrollHoldDuration: TimeInterval = 0.3
    private static let servicePickerTitle = "Services Through the Tunnel"
    private static let tunnelEditorTitle = "Edit Tunnel"
    private static let selectedServicesPattern = "[0-9]+ services? selected"
    private static let summaryScrolls = 6

    func tunnelRows(startingWith prefix: String) -> XCUIElementQuery {
        staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
    }

    func prepareCopy(of name: String, named copyName: String) {
        deleteTunnels(named: copyName)
        deleteNumberedCopies(of: name)
        guard let copy = duplicateTunnel(named: name) else { return }
        copy.tap()
        tapButton("Edit Tunnel")
        replaceText(inField: "Name", with: copyName)
        tapButton("Save", inNavigationBar: Self.tunnelEditorTitle)
        XCTAssertTrue(staticTexts["Routing"].waitForExistence(timeout: Self.liveElementTimeout), "No \(copyName)")
    }

    func duplicateTunnel(named name: String) -> XCUIElement? {
        let original = tunnelRows(startingWith: name).firstMatch
        XCTAssertTrue(original.waitForExistence(timeout: Self.liveElementTimeout), "No tunnel \(name)")
        revealSwipeActions(of: original)
        tapButton("Duplicate")
        let copies = tunnelRows(startingWith: "\(name) ")
        XCTAssertTrue(copies.firstMatch.waitForExistence(timeout: Self.liveElementTimeout), "No copy of \(name)")
        return copies.allElementsBoundByIndex.last
    }

    func deleteTunnels(named name: String) {
        deleteTunnels(matching: NSPredicate(format: "label BEGINSWITH %@", name))
    }

    private func deleteNumberedCopies(of name: String) {
        let pattern = NSRegularExpression.escapedPattern(for: name) + " [0-9]+, .*"
        deleteTunnels(matching: NSPredicate(format: "label MATCHES %@", pattern))
    }

    private func deleteTunnels(matching predicate: NSPredicate) {
        for _ in 0..<Self.leftoverDeletions {
            let row = staticTexts.matching(predicate).firstMatch
            guard row.exists else { return }
            let label = row.label
            revealSwipeActions(of: row)
            tapButton("Delete")
            let confirmation = staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Delete “")).firstMatch
            XCTAssertTrue(confirmation.waitForExistence(timeout: Self.liveElementTimeout), "No deletion question")
            tapButton("Delete")
            XCTAssertTrue(staticTexts[label].waitForNonExistence(timeout: Self.liveElementTimeout), "\(label) stayed")
        }
    }

    func disconnectEveryTunnel() {
        for toggle in switches.allElementsBoundByIndex where toggle.value as? String == "1" {
            toggle.tap()
            let switchedOff = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '0'"), object: toggle)
            XCTAssertEqual(XCTWaiter().wait(for: [switchedOff], timeout: Self.liveElementTimeout), .completed)
        }
    }

    func returnToTunnelList() {
        let back = navigationBars.buttons.matching(LocalizedLabels.predicate("Tunnels")).firstMatch
        if back.waitForExistence(timeout: Self.liveElementTimeout) {
            back.tap()
        }
    }

    func routeAllTraffic() {
        XCTAssertTrue(staticTexts["Routing"].waitForExistence(timeout: Self.liveElementTimeout), "No tunnel details")
        guard !staticTexts["All traffic"].exists else { return }
        tapButton("Edit Tunnel")
        chooseRoutingMode("All traffic")
        tapButton("Save", inNavigationBar: Self.tunnelEditorTitle)
        XCTAssertTrue(staticTexts["All traffic"].waitForExistence(timeout: Self.liveElementTimeout))
    }

    func routeSelectedServices(_ services: [String], andOwnService name: String, domains: [String]) {
        chooseRoutingMode("Selected services")
        let rememberedCount = selectedServiceCount()
        scrollToButton("Choose Services…")
        let switchedOnCount = switchOnServices(services)
        tapButton("Add Service", inNavigationBar: Self.servicePickerTitle)
        replaceText(inField: "Service name", with: name)
        type(domains.joined(separator: "\n"), intoTextView: "Domains")
        tapButton("Save", inNavigationBar: "New Service")
        tapButton("Done", inNavigationBar: Self.servicePickerTitle)
        waitForText(Self.selectedServicesText(count: rememberedCount + switchedOnCount + 1))
        tapButton("Save", inNavigationBar: Self.tunnelEditorTitle)
    }

    func deleteOwnServices(named name: String) {
        tapButton("Edit Tunnel")
        scrollToButton("Choose Services…")
        for _ in 0..<Self.leftoverDeletions {
            guard let row = scrollToServiceRow(named: name) else { break }
            point(CGPoint(x: row.frame.minX + Self.rowLabelInset, y: row.frame.midY))
                .press(forDuration: Self.contextMenuPressDuration)
            tapButton("Delete")
            XCTAssertTrue(buttons["Details"].waitForNonExistence(timeout: Self.liveElementTimeout))
        }
        tapButton("Done", inNavigationBar: Self.servicePickerTitle)
        tapButton("Save", inNavigationBar: Self.tunnelEditorTitle)
    }

    private func selectedServiceCount() -> Int {
        let countText = NSPredicate(format: "label MATCHES %@", Self.selectedServicesPattern)
        let summary = staticTexts.matching(countText).firstMatch
        var scrolls = 0
        while !summary.exists, scrolls < Self.summaryScrolls {
            swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(summary.waitForExistence(timeout: Self.liveElementTimeout), "No count of selected services")
        return Int(summary.label.prefix { character in character.isNumber }) ?? 0
    }

    private static func selectedServicesText(count: Int) -> String {
        count == 1 ? "1 service selected" : "\(count) services selected"
    }

    @discardableResult
    func switchOnServices(_ services: [String]) -> Int {
        var remaining = Set(services)
        var switchedOn: Set<String> = []
        var steps = 0
        while !remaining.isEmpty, steps < services.count * Self.attemptsPerService + Self.serviceListScrolls {
            steps += 1
            let rows = visibleServiceRows(named: remaining)
            for row in rows where row.value as? String == "1" {
                remaining.remove(row.label)
            }
            if let row = rows.first(where: { row in row.value as? String != "1" }) {
                switchedOn.insert(row.label)
                point(CGPoint(x: row.frame.maxX - Self.switchKnobInset, y: row.frame.midY)).tap()
            } else if !remaining.isEmpty {
                scrollWithoutMomentum()
            }
        }
        XCTAssertTrue(remaining.isEmpty, "Services stayed off: \(remaining.sorted())")
        return switchedOn.count
    }

    private func scrollToServiceRow(named name: String) -> (any XCUIElementSnapshot)? {
        for _ in 0...Self.serviceListScrolls {
            if let row = visibleServiceRows(named: [name]).first {
                return row
            }
            scrollWithoutMomentum()
        }
        return nil
    }

    private func visibleServiceRows(named names: Set<String>) -> [any XCUIElementSnapshot] {
        guard let tree = try? snapshot() else { return [] }
        let nodes = Self.descendants(of: tree)
        let titles = LocalizedLabels.matching(Self.servicePickerTitle)
        let title = nodes.first { node in
            node.elementType == .navigationBar && titles.contains(node.identifier)
        }
        let search = nodes.first { node in node.elementType == .searchField }
        let top = title?.frame.maxY ?? frame.minY
        let searchTop = search?.frame.minY ?? frame.maxY
        let bottom = searchTop > top ? searchTop : frame.maxY
        return nodes.filter { node in
            node.elementType == .switch && names.contains(node.label)
                && node.frame.minY >= top && node.frame.maxY <= bottom
        }
    }

    private static func descendants(of node: any XCUIElementSnapshot) -> [any XCUIElementSnapshot] {
        [node] + node.children.flatMap(descendants)
    }

    private func point(_ location: CGPoint) -> XCUICoordinate {
        coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: location.x, dy: location.y))
    }

    private func revealSwipeActions(of row: XCUIElement) {
        row.coordinate(withNormalizedOffset: Self.swipeActionsStart).press(
            forDuration: Self.scrollPressDuration,
            thenDragTo: row.coordinate(withNormalizedOffset: Self.swipeActionsEnd),
            withVelocity: .slow,
            thenHoldForDuration: Self.scrollHoldDuration
        )
    }

    private func scrollWithoutMomentum() {
        coordinate(withNormalizedOffset: Self.scrollStart).press(
            forDuration: Self.scrollPressDuration,
            thenDragTo: coordinate(withNormalizedOffset: Self.scrollEnd),
            withVelocity: .slow,
            thenHoldForDuration: Self.scrollHoldDuration
        )
    }
}
