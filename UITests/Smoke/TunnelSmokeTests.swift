import XCTest

final class TunnelSmokeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testImportsAPastedTunnelAndRenamesIt() {
        SplitwayLaunch.copyToClipboard(SampleConfigurationText.make())
        let application = SplitwayLaunch.application()

        application.addTunnel(by: "Paste")
        application.waitForText("Import Tunnels")
        application.tapButton("Import")
        application.tapButton("Done")
        application.tapText(startingWith: "Pasted tunnel")
        application.tapButton("Edit Tunnel")
        application.replaceText(inField: "Name", with: "Office Prague")
        application.tapButton("Save")

        application.waitForText(startingWith: "Office Prague")
    }

    @MainActor
    func testCreatesATunnelFromScratch() {
        let application = SplitwayLaunch.application()

        application.addTunnel(by: "Create from scratch")
        application.replaceText(inField: "Name", with: "Home Lab")
        application.scrollToButton("Add peer")
        application.type(RandomKeyText.make(), intoField: "Public key")
        application.tapButton("Save")

        application.waitForText(startingWith: "Home Lab")
    }
}
