import XCTest

final class StoreMaterialsTests: XCTestCase {
    private struct DemoTunnel {
        let name: String
        let endpoint: String
    }

    private static let executionAllowance: TimeInterval = 600
    private static let demoTunnels = [
        "en": [
            DemoTunnel(name: "Prague", endpoint: "prague.example.net:51820"),
            DemoTunnel(name: "Amsterdam", endpoint: "amsterdam.example.net:51820"),
            DemoTunnel(name: "Home", endpoint: "home.example.net:51820"),
        ],
        "ru": [
            DemoTunnel(name: "Прага", endpoint: "prague.example.net:51820"),
            DemoTunnel(name: "Амстердам", endpoint: "amsterdam.example.net:51820"),
            DemoTunnel(name: "Дом", endpoint: "home.example.net:51820"),
        ],
    ]
    private static let demoServices = ["Telegram", "YouTube", "ChatGPT", "Claude"]
    private static let videoServices = ["Telegram", "YouTube"]

    private static var tunnels: [DemoTunnel] {
        demoTunnels[LocalizedLabels.language] ?? demoTunnels["en"] ?? []
    }

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SPLITWAY_MATERIALS"] == "YES",
            "Captures screenshots and a video for the site and the store"
        )
        continueAfterFailure = false
        executionTimeAllowance = Self.executionAllowance
    }

    @MainActor
    func testCapturesTheMainScreens() throws {
        let onboarding = SplitwayLaunch.application(hasCompletedOnboarding: false)
        onboarding.waitForText("Welcome to Splitway")
        Self.keepScreen(named: "01-welcome")
        onboarding.terminate()

        let application = SplitwayLaunch.application()
        for tunnel in Self.tunnels.reversed() {
            Self.createTunnel(tunnel, in: application)
        }
        let featured = try XCTUnwrap(Self.tunnels.first)
        application.tapText(startingWith: featured.name)
        application.tapButton("Edit Tunnel")
        application.chooseRoutingMode("Selected services")
        application.scrollToButton("Choose Services…")
        application.switchOnServices(Self.demoServices)
        Self.keepScreen(named: "03-services")
        application.tapButton("Done", inNavigationBar: "Services Through the Tunnel")
        application.tapButton("Save", inNavigationBar: "Edit Tunnel")
        application.waitForText("Services through the tunnel")
        Self.keepScreen(named: "04-details")
        application.returnToTunnelList()
        Self.keepScreen(named: "02-tunnels")
        application.tapText(startingWith: Self.tunnels[1].name)
        application.tapButton("Edit Tunnel")
        application.waitForText("Interface")
        Self.keepScreen(named: "05-editor")
    }

    @MainActor
    func testShowsHowToChooseServices() throws {
        let application = SplitwayLaunch.application()
        let featured = try XCTUnwrap(Self.tunnels.first)

        Self.createTunnel(featured, in: application)
        application.tapText(startingWith: featured.name)
        application.tapButton("Edit Tunnel")
        application.chooseRoutingMode("Selected services")
        application.scrollToButton("Choose Services…")
        application.switchOnServices(Self.videoServices)
        application.tapButton("Done", inNavigationBar: "Services Through the Tunnel")
        application.tapButton("Save", inNavigationBar: "Edit Tunnel")

        application.waitForText("Services through the tunnel")
    }

    @MainActor
    private static func createTunnel(_ tunnel: DemoTunnel, in application: XCUIApplication) {
        application.addTunnel(by: "Create from scratch")
        application.replaceText(inField: "Name", with: tunnel.name)
        application.scrollToButton("Add peer")
        application.type(RandomKeyText.make(), intoField: "Public key")
        application.type(tunnel.endpoint, intoField: "Endpoint")
        application.tapButton("Save")
        application.waitForText(startingWith: tunnel.name)
        application.returnToTunnelList()
    }

    @MainActor
    private static func keepScreen(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: name) { activity in activity.add(attachment) }
    }
}
