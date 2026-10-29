import AppRouting
import SharedKernel

public enum FlowRoutingFixtures {
    public static let browserTeam = "BROWSER123"
    public static let tunnelAddress = IPAddress.ipv4(0x0A01_0203)
    public static let tunnelIPv6Address = IPAddress.ipv6(0x2001_0DB8 << 96 | 1)
    public static let outsideAddress = IPAddress.ipv4(0xC000_020A)

    public static let browser = SourceApplication(
        signingIdentifier: "com.example.browser",
        teamIdentifier: browserTeam,
        executablePath: "/Applications/Browser.app/Contents/MacOS/Browser"
    )
    public static let browserHelper = SourceApplication(
        signingIdentifier: "com.example.browser.helper",
        teamIdentifier: browserTeam,
        executablePath: "/Applications/Browser.app/Contents/Frameworks/Helper.app/Contents/MacOS/Helper"
    )
    public static let spoofedBrowser = SourceApplication(
        signingIdentifier: "com.example.browser",
        teamIdentifier: "INTRUDER99",
        executablePath: "/Users/someone/Downloads/Browser"
    )
    public static let spoofedCurl = SourceApplication(
        signingIdentifier: "com.apple.curl",
        teamIdentifier: "INTRUDER99",
        executablePath: "/Users/someone/curl"
    )
    public static let unsignedCurl = SourceApplication(
        signingIdentifier: nil, teamIdentifier: nil, executablePath: "/usr/bin/curl")
    public static let bundledExecutable = SourceApplication(
        signingIdentifier: nil,
        teamIdentifier: browserTeam,
        executablePath: "/Applications/Browser.app/Contents/Helpers/updater"
    )
    public static let neighbourExecutable = SourceApplication(
        signingIdentifier: nil,
        teamIdentifier: browserTeam,
        executablePath: "/Applications/Browser.app Tools/updater"
    )
    public static let otherApplication = SourceApplication(
        signingIdentifier: "com.example.mail",
        teamIdentifier: "MAIL123456",
        executablePath: "/Applications/Mail Client.app/Contents/MacOS/Mail Client"
    )

    public static func snapshot(whenTunnelUnavailable: TunnelUnavailableBehavior = .block) throws
        -> RoutingPolicySnapshot
    {
        RoutingPolicySnapshot(
            applications: [
                try ApplicationIdentity(
                    kind: .application,
                    displayName: "Browser",
                    path: "/Applications/Browser.app",
                    signingIdentifiers: ["com.example.browser", "com.example.browser.helper"],
                    teamIdentifier: browserTeam
                ),
                try ApplicationIdentity(
                    kind: .commandLineTool,
                    displayName: "curl",
                    path: "/usr/bin/curl",
                    signingIdentifiers: ["com.apple.curl"]
                ),
            ],
            tunnelNetworks: IPNetworkSet([try IPNetwork("10.0.0.0/8"), try IPNetwork("2001:db8::/32")]),
            whenTunnelUnavailable: whenTunnelUnavailable
        )
    }
}
