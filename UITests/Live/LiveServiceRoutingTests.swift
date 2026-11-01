import XCTest

final class LiveServiceRoutingTests: XCTestCase {
    private static let connectionTimeout: TimeInterval = 30
    private static let defaultTunnelName = "cz-prg"
    private static let checkTunnelName = "Splitway live check"
    private static let checkServiceName = "Live check"
    private static let checkHosts = ["api.ipify.org", "proof.ovh.net"]
    private static let otherHost = "icanhazip.com"
    private static let traceHosts = ["chatgpt.com", "claude.ai"]
    private static let interruptionDelay = Duration.seconds(3)
    private static let interruptionWatchdog = Duration.seconds(60)
    private static let recoveryDeadline: TimeInterval = 120
    private static let catalogServices = [
        "Telegram", "WhatsApp", "Signal", "Instagram", "Facebook", "Threads", "YouTube", "X",
        "Discord", "ChatGPT", "Claude", "Spotify", "Netflix", "LinkedIn", "GitHub",
    ]
    private static let catalogHosts = [
        "telegram.org", "web.whatsapp.com", "signal.org", "www.instagram.com", "www.facebook.com",
        "www.threads.com", "www.youtube.com", "x.com", "discord.com", "chatgpt.com", "claude.ai",
        "open.spotify.com", "www.netflix.com", "www.linkedin.com", "github.com",
    ]

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL"] == "YES",
            "Runs only on a device that has the test tunnel"
        )
        continueAfterFailure = false
    }

    @MainActor
    func testSelectedServicesGoThroughTheTunnelAndEverythingElseStaysDirect() async throws {
        let application = SplitwayLaunch.applicationWithStoredTunnels()
        application.disconnectEveryTunnel()
        Self.prepareCheckTunnel(in: application)
        let connectionSwitch = application.switches["Connection"].switches.firstMatch
        XCTAssertTrue(connectionSwitch.waitForExistence(timeout: Self.connectionTimeout))
        let direct = try await ServicePathSnapshot.measure()

        connectionSwitch.tap()
        XCTAssertTrue(application.staticTexts["Connected"].waitForExistence(timeout: Self.connectionTimeout))
        let tunnel = try await ServicePathSnapshot.measure()
        let routing = await ServiceRoutingChecks.measure(
            selectedHosts: Self.checkHosts + Self.catalogHosts,
            otherHost: Self.otherHost,
            traceHosts: Self.traceHosts,
            tunnel: tunnel,
            direct: direct
        )
        let load = await ServiceRoutingLoad.measure()
        let interruption = try await Self.interruptedDownload(switchingOff: connectionSwitch, in: application)
        let recovery = await Self.recovery(expecting: direct.selectedAddress)
        Self.cleanUp(application)

        let summary = Self.summary(direct: direct, tunnel: tunnel, routing: routing)
        Self.keep("\(summary) \(load.summary) interruption=\(interruption) recovery=\(recovery)")
        Self.assertRouting(direct: direct, tunnel: tunnel, routing: routing)
        XCTAssertTrue(load.tunnelCompleted, "A download through the tunnel failed")
        XCTAssertTrue(recovery.hasPrefix(Self.recoveredPrefix), "The selected domain stayed in the tunnel")
    }

    private static let recoveredPrefix = "direct-after-"

    @MainActor
    private static func prepareCheckTunnel(in application: XCUIApplication) {
        let tunnelName = ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL_NAME"] ?? defaultTunnelName
        application.deleteTunnels(named: checkTunnelName)
        guard let copy = application.duplicateTunnel(named: tunnelName) else { return }
        copy.tap()
        application.tapButton("Edit Tunnel")
        application.replaceText(inField: "Name", with: checkTunnelName)
        application.routeSelectedServices(
            catalogServices,
            andOwnService: checkServiceName,
            domains: checkHosts + [ResolverIdentityProbe.resolverEchoName]
        )
    }

    @MainActor
    private static func cleanUp(_ application: XCUIApplication) {
        application.deleteOwnServices(named: checkServiceName)
        application.returnToTunnelList()
        application.deleteTunnels(named: checkTunnelName)
    }

    @MainActor
    private static func interruptedDownload(
        switchingOff connectionSwitch: XCUIElement,
        in application: XCUIApplication
    ) async throws -> String {
        let download = Task {
            try await ServiceRoutingProbe.downloadedByteCount(from: ServiceRoutingLoad.tunnelAddress)
        }
        try await Task.sleep(for: interruptionDelay)
        connectionSwitch.tap()
        let switchedOff = Date()
        XCTAssertTrue(application.staticTexts["Disconnected"].waitForExistence(timeout: connectionTimeout))
        let watchdog = Task {
            try await Task.sleep(for: interruptionWatchdog)
            download.cancel()
        }
        let outcome = await download.result
        watchdog.cancel()
        let seconds = String(format: "%.1f", Date().timeIntervalSince(switchedOff))
        switch outcome {
        case .success(let bytes):
            return "completed-\(bytes)-bytes-\(seconds)s-after-switch-off"
        case .failure(let error):
            return "failed-\(seconds)s-after-switch-off-code-\((error as? URLError)?.code.rawValue ?? 0)"
        }
    }

    private static func recovery(expecting directAddress: String) async -> String {
        let started = Date()
        var attempts = 0
        while Date().timeIntervalSince(started) < recoveryDeadline {
            attempts += 1
            let address = try? await ServiceRoutingProbe.text(at: ServicePathSnapshot.selectedAddressService)
            if address == directAddress {
                let seconds = String(format: "%.1f", Date().timeIntervalSince(started))
                return "\(recoveredPrefix)\(seconds)s-attempts-\(attempts)"
            }
            try? await Task.sleep(for: .seconds(1))
        }
        return "not-direct-within-\(Int(recoveryDeadline))s"
    }

    private static func summary(
        direct: ServicePathSnapshot,
        tunnel: ServicePathSnapshot,
        routing: ServiceRoutingChecks
    ) -> String {
        "selected-through-tunnel=\(tunnel.selectedAddress != direct.selectedAddress)"
            + " other-direct=\(tunnel.otherAddress == direct.otherAddress)"
            + " resolver-through-tunnel=\(!tunnel.resolverEcho.isEmpty && tunnel.resolverEcho != direct.resolverEcho)"
            + " \(routing.summary)"
    }

    private static func assertRouting(
        direct: ServicePathSnapshot,
        tunnel: ServicePathSnapshot,
        routing: ServiceRoutingChecks
    ) {
        XCTAssertTrue(tunnel.selectedAddress != direct.selectedAddress, "The selected domain did not use the tunnel")
        XCTAssertTrue(tunnel.otherAddress == direct.otherAddress, "Another domain went through the tunnel")
        XCTAssertTrue(
            !tunnel.resolverEcho.isEmpty && tunnel.resolverEcho != direct.resolverEcho,
            "The selected domain was not resolved through the tunnel"
        )
        XCTAssertTrue(
            routing.selectedHostsNotOnlyFake.isEmpty,
            "Not only fake answers: \(routing.selectedHostsNotOnlyFake)"
        )
        XCTAssertTrue(
            routing.connectionsOutsideFakeAddresses.isEmpty,
            "Connections outside the tunnel: \(routing.connectionsOutsideFakeAddresses)"
        )
        XCTAssertFalse(routing.otherHostAnswersAreFake, "Another domain resolved to a fake address")
        XCTAssertTrue(
            routing.traceHostsOutsideTheTunnel.isEmpty,
            "Outside the tunnel: \(routing.traceHostsOutsideTheTunnel)"
        )
    }

    @MainActor
    private static func keep(_ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = "Live service routing"
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Live service routing") { activity in activity.add(attachment) }
    }
}
