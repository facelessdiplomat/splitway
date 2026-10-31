import XCTest

final class LiveServiceRoutingTests: XCTestCase {
    private static let connectionTimeout: TimeInterval = 30
    private static let defaultTunnelName = "cz-prg"
    private static let selectedService = "https://api.ipify.org"
    private static let otherService = "https://icanhazip.com"
    private static let selectedHosts = ["api.ipify.org", "proof.ovh.net"]
    private static let otherHost = "icanhazip.com"
    private static let loadAddress = "https://proof.ovh.net/files/1Gb.dat"
    private static let loadStreamCount = 2
    private static let interruptionDelay = Duration.seconds(3)
    private static let requestTimeout: TimeInterval = 15
    private static let idleTimeout: TimeInterval = 30
    private static let loadTimeout: TimeInterval = 600
    private static let recoveryDeadline: TimeInterval = 120
    private static let fakeNetworkFirstOctet: UInt32 = 198
    private static let fakeNetworkSecondOctets: ClosedRange<UInt32> = 18...19

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL"] == "YES",
            "Runs only on a device that has the test tunnel"
        )
        continueAfterFailure = true
    }

    @MainActor
    func testSelectedDomainsUseTheTunnelAndOtherDomainsStayDirect() async throws {
        let application = SplitwayLaunch.applicationWithStoredTunnels()
        let connectionSwitch = Self.disconnectedSwitch(in: application)
        let directSelected = try await Self.text(at: Self.selectedService)
        let directOther = try await Self.text(at: Self.otherService)

        connectionSwitch.tap()
        XCTAssertTrue(application.staticTexts["Connected"].waitForExistence(timeout: Self.connectionTimeout))
        let selectedUsesTheTunnel = try await Self.text(at: Self.selectedService) != directSelected
        let otherStaysDirect = try await Self.text(at: Self.otherService) == directOther
        let selectedAnswersAreFake = Self.selectedHosts.allSatisfy(Self.answersWithFakeAddresses)
        let otherAnswersAreFake = Self.answersWithFakeAddresses(Self.otherHost)
        let load = try await Self.parallelDownload()
        let interruption = try await Self.interruptedDownload(switchingOff: connectionSwitch, in: application)
        let recovery = await Self.recovery(of: Self.selectedService, expecting: directSelected)

        Self.keep(
            "selected-through-tunnel=\(selectedUsesTheTunnel) other-direct=\(otherStaysDirect)"
                + " selected-answers-fake=\(selectedAnswersAreFake) other-answers-fake=\(otherAnswersAreFake)"
                + " load-bytes=\(load.bytes) load-seconds=\(String(format: "%.2f", load.seconds))"
                + " interruption=\(interruption) recovery=\(recovery)"
        )
        XCTAssertTrue(selectedUsesTheTunnel, "The selected domain did not go through the tunnel")
        XCTAssertTrue(otherStaysDirect, "Another domain went through the tunnel")
        XCTAssertTrue(selectedAnswersAreFake, "A selected domain resolved to a real address")
        XCTAssertFalse(otherAnswersAreFake, "Another domain resolved to a fake address")
    }

    @MainActor
    private static func disconnectedSwitch(in application: XCUIApplication) -> XCUIElement {
        let tunnelName = ProcessInfo.processInfo.environment["SPLITWAY_LIVE_TUNNEL_NAME"] ?? defaultTunnelName
        application.tapText(startingWith: tunnelName)
        let connectionSwitch = application.switches["Connection"].switches.firstMatch
        XCTAssertTrue(connectionSwitch.waitForExistence(timeout: connectionTimeout))
        if application.staticTexts["Connected"].exists {
            connectionSwitch.tap()
            XCTAssertTrue(application.staticTexts["Disconnected"].waitForExistence(timeout: connectionTimeout))
        }
        return connectionSwitch
    }

    private static func text(at address: String) async throws -> String {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: try XCTUnwrap(URL(string: address)))
        request.timeoutInterval = requestTimeout
        let (data, _) = try await session.data(for: request)
        return String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func answersWithFakeAddresses(_ host: String) -> Bool {
        let addresses = ipv4Addresses(of: host)
        return !addresses.isEmpty
            && addresses.allSatisfy { address in
                address >> 24 == fakeNetworkFirstOctet && fakeNetworkSecondOctets.contains(address >> 16 & 0xFF)
            }
    }

    private static func ipv4Addresses(of host: String) -> [UInt32] {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM
        var list: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &list) == 0, let first = list else { return [] }
        defer { freeaddrinfo(first) }
        return sequence(first: first) { entry in entry.pointee.ai_next }.compactMap { entry in
            entry.pointee.ai_addr?.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { address in
                UInt32(bigEndian: address.pointee.sin_addr.s_addr)
            }
        }
    }

    private static func downloadedByteCount(from address: String) async throws -> Int {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = idleTimeout
        configuration.timeoutIntervalForResource = loadTimeout
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let (location, _) = try await session.download(from: try XCTUnwrap(URL(string: address)))
        defer { try? FileManager.default.removeItem(at: location) }
        return try location.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }

    private static func parallelDownload() async throws -> (bytes: Int, seconds: Double) {
        let started = Date()
        let bytes = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<loadStreamCount {
                group.addTask { try await downloadedByteCount(from: loadAddress) }
            }
            return try await group.reduce(0, +)
        }
        return (bytes, Date().timeIntervalSince(started))
    }

    @MainActor
    private static func interruptedDownload(
        switchingOff connectionSwitch: XCUIElement,
        in application: XCUIApplication
    ) async throws -> String {
        let download = Task { try await downloadedByteCount(from: loadAddress) }
        try await Task.sleep(for: interruptionDelay)
        connectionSwitch.tap()
        let switchedOff = Date()
        XCTAssertTrue(application.staticTexts["Disconnected"].waitForExistence(timeout: connectionTimeout))
        let outcome = await download.result
        let seconds = String(format: "%.1f", Date().timeIntervalSince(switchedOff))
        switch outcome {
        case .success(let bytes):
            return "completed-\(bytes)-bytes-\(seconds)s-after-switch-off"
        case .failure(let error):
            return "failed-\(seconds)s-after-switch-off-code-\((error as? URLError)?.code.rawValue ?? 0)"
        }
    }

    private static func recovery(of address: String, expecting directAddress: String) async -> String {
        let started = Date()
        var attempts = 0
        while Date().timeIntervalSince(started) < recoveryDeadline {
            attempts += 1
            if let text = try? await text(at: address), text == directAddress {
                return "direct-after-\(String(format: "%.1f", Date().timeIntervalSince(started)))s-attempts-\(attempts)"
            }
            try? await Task.sleep(for: .seconds(1))
        }
        return "not-direct-within-\(Int(recoveryDeadline))s"
    }

    @MainActor
    private static func keep(_ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = "SP-4 results"
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "SP-4 results") { activity in activity.add(attachment) }
    }
}
