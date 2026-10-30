import AppRouting
import Testing
import TransparentProxy
import TransparentProxyTestSupport

@Suite
struct SuspiciousAttributionMonitorTests {
    private static let otherProxyPath =
        "/Library/SystemExtensions/7F3A2B10-4C5D-4E6F-8A9B-0C1D2E3F4A5B/com.example.proxy.systemextension"
        + "/Contents/MacOS/com.example.proxy"

    private let log = RecordingSuspiciousAttributionLog()

    @Test
    func recordsTheFlowsOfAnotherNetworkExtensionOnce() {
        let monitor = SuspiciousAttributionMonitor(log: log)
        let source = SourceApplication(
            signingIdentifier: "com.example.proxy",
            teamIdentifier: "PROXY12345",
            executablePath: Self.otherProxyPath
        )

        monitor.inspect(source)
        monitor.inspect(source)

        #expect(log.networkExtensionPaths == [Self.otherProxyPath])
    }

    @Test(arguments: ["/Applications/Browser.app/Contents/MacOS/Browser", "/usr/bin/curl"])
    func ignoresTheFlowsOfApplications(_ executablePath: String) {
        let monitor = SuspiciousAttributionMonitor(log: log)

        monitor.inspect(SourceApplication(signingIdentifier: nil, teamIdentifier: nil, executablePath: executablePath))

        #expect(log.networkExtensionPaths.isEmpty)
    }

    @Test
    func ignoresTheFlowsOfAnUnknownSource() {
        let monitor = SuspiciousAttributionMonitor(log: log)

        monitor.inspect(SourceApplication(signingIdentifier: nil, teamIdentifier: nil, executablePath: nil))

        #expect(log.networkExtensionPaths.isEmpty)
    }
}
