import XCTest

@MainActor
enum SplitwayLaunch {
    private static let launchTimeout: TimeInterval = 10

    static func application(hasCompletedOnboarding: Bool = true) -> XCUIApplication {
        let application = XCUIApplication()
        application.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-SplitwayUsesTemporaryStorage", "YES",
            "-Splitway.hasCompletedOnboarding", hasCompletedOnboarding ? "YES" : "NO",
        ]
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: launchTimeout))
        return application
    }
}
