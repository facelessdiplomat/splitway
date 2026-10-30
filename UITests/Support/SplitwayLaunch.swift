import XCTest

@MainActor
enum SplitwayLaunch {
    private static let launchTimeout: TimeInterval = 10

    static func application(hasCompletedOnboarding: Bool = true) -> XCUIApplication {
        launch(arguments: [
            "-SplitwayUsesTemporaryStorage", "YES",
            "-Splitway.hasCompletedOnboarding", hasCompletedOnboarding ? "YES" : "NO",
        ])
    }

    static func applicationWithStoredTunnels() -> XCUIApplication {
        launch(arguments: ["-Splitway.hasCompletedOnboarding", "YES"])
    }

    private static func launch(arguments: [String]) -> XCUIApplication {
        let application = XCUIApplication()
        application.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + arguments
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: launchTimeout))
        return application
    }
}
