import XCTest

final class ServicePickerTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testChoosesAServiceAndAddsOwnOneWithoutLeavingTheEditor() throws {
        let application = SplitwayLaunch.application()
        application.addTunnel(by: "Create from scratch")
        application.replaceText(inField: "Name", with: "Phone")

        application.chooseRoutingMode("Selected services")
        application.scrollToButton("Choose Services…")
        application.waitForText("Messaging")
        try application.auditAccessibility(ofSheet: true)
        application.switchOn("Telegram")
        application.tapButton("Add Service", inNavigationBar: "Services Through the Tunnel")
        application.replaceText(inField: "Service name", with: "Office")
        application.type("corp.example", intoTextView: "Domains")
        try application.auditAccessibility(ofSheet: true)
        application.tapButton("Save", inNavigationBar: "New Service")
        application.tapButton("Done", inNavigationBar: "Services Through the Tunnel")

        application.waitForText(counting: 2, in: "%lld services selected")
        application.scrollToButton("Add peer")
        application.type(RandomKeyText.make(), intoField: "Public key")
        application.tapButton("Save", inNavigationBar: "New Tunnel")
        application.tapText(startingWith: "Phone")
        application.waitForText("Services through the tunnel")
        application.waitForText("Telegram")
        application.waitForText("Office")
    }
}
