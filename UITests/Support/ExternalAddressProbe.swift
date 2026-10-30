import XCTest

@MainActor
enum ExternalAddressProbe {
    enum Failure: Error {
        case addressNotShown
    }

    private static let addressService = "https://api.ipify.org"
    private static let safariIdentifier = "com.apple.mobilesafari"
    private static let addressPattern = /^[0-9]{1,3}(\.[0-9]{1,3}){3}$|^[0-9a-fA-F:]+:[0-9a-fA-F:]+$/
    private static let pageTimeout: TimeInterval = 30
    private static let pollInterval: TimeInterval = 0.5

    static func currentAddress() throws -> String {
        let service = try XCTUnwrap(URL(string: addressService))
        XCUIDevice.shared.system.open(service)
        let safari = XCUIApplication(bundleIdentifier: safariIdentifier)
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: pageTimeout))
        let deadline = Date().addingTimeInterval(pageTimeout)
        while Date() < deadline {
            if let address = address(shownIn: safari) {
                return address
            }
            RunLoop.current.run(until: Date().addingTimeInterval(pollInterval))
        }
        throw Failure.addressNotShown
    }

    private static func address(shownIn safari: XCUIApplication) -> String? {
        safari.webViews.staticTexts.allElementsBoundByIndex
            .map(\.label)
            .first { label in label.wholeMatch(of: addressPattern) != nil }
    }
}
