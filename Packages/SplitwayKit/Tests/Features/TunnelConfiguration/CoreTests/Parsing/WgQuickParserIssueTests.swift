import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct WgQuickParserIssueTests {
    private static let interfaceSection = [
        "[Interface]",
        "PrivateKey = \(SampleKeys.interfacePrivateKeyText)",
        "Address = 10.14.0.2/16",
    ]
    private static let peerSection = [
        "[Peer]",
        "PublicKey = \(SampleKeys.firstPeerPublicKeyText)",
        "AllowedIPs = 0.0.0.0/0",
    ]

    @Test
    func reportsUnknownKeysWithTheirLine() {
        let result = parse(Self.interfaceSection + ["Colour = blue"] + Self.peerSection)

        #expect(result.issues == [ConfigurationIssue(line: 4, kind: .unknownKey("Colour"))])
        #expect(result.configuration == nil)
    }

    @Test
    func warnsAboutWgQuickHooksAndStillParses() {
        let result = WgQuickConfigurationParser.parse(WgQuickFixtures.wgQuickHooks)

        #expect(
            result.issues == [
                ConfigurationIssue(line: 4, kind: .unsupportedWgQuickKey("PostUp")),
                ConfigurationIssue(line: 5, kind: .unsupportedWgQuickKey("PreDown")),
                ConfigurationIssue(line: 6, kind: .unsupportedWgQuickKey("Table")),
                ConfigurationIssue(line: 7, kind: .unsupportedWgQuickKey("SaveConfig")),
            ]
        )
        #expect(result.issues.allSatisfy { $0.severity == .warning })
        #expect(result.configuration != nil)
    }

    @Test
    func explainsThatAmneziaWGConfigurationsAreNotSupported() {
        let result = WgQuickConfigurationParser.parse(WgQuickFixtures.amneziaWG)

        #expect(
            result.issues == [
                ConfigurationIssue(line: 4, kind: .amneziaWGNotSupported("Jc")),
                ConfigurationIssue(line: 5, kind: .amneziaWGNotSupported("Jmin")),
                ConfigurationIssue(line: 6, kind: .amneziaWGNotSupported("H1")),
            ]
        )
        #expect(result.configuration == nil)
    }

    @Test
    func requiresExactlyOneInterfaceSection() {
        #expect(parse(Self.peerSection).issues == [ConfigurationIssue(line: nil, kind: .missingInterfaceSection)])
        #expect(
            parse(Self.interfaceSection + Self.interfaceSection + Self.peerSection).issues == [
                ConfigurationIssue(line: 4, kind: .multipleInterfaceSections)
            ]
        )
    }

    @Test
    func requiresThePrivateKeyAndPeerPublicKeys() {
        let result = parse(["[Interface]", "Address = 10.14.0.2/16", "[Peer]", "AllowedIPs = 0.0.0.0/0"])

        #expect(
            result.issues == [
                ConfigurationIssue(line: 1, kind: .missingPrivateKey),
                ConfigurationIssue(line: 3, kind: .missingPeerPublicKey),
            ]
        )
    }

    @Test
    func reportsInvalidValuesWithTheKeyAndReason() {
        let result = parse(
            Self.interfaceSection + ["MTU = 100"] + Self.peerSection + [
                "Endpoint = vpn.example.com", "AllowedIPs = 10.0.0.0/33",
            ]
        )

        #expect(
            result.issues == [
                ConfigurationIssue(line: 4, kind: .invalidValue(.mtu, .mtu(.outOfRange))),
                ConfigurationIssue(line: 8, kind: .invalidValue(.endpoint, .endpoint(.missingPort))),
                ConfigurationIssue(line: 9, kind: .invalidValue(.allowedIPs, .network(.prefixLengthOutOfRange))),
            ]
        )
    }

    @Test
    func rejectsRepeatedSingleValueKeysAndKeysInTheWrongSection() {
        let result = parse(
            Self.interfaceSection + ["MTU = 1420", "MTU = 1280", "Endpoint = 203.0.113.7:51820"] + Self.peerSection)

        #expect(
            result.issues == [
                ConfigurationIssue(line: 5, kind: .duplicateKey(.mtu)),
                ConfigurationIssue(line: 6, kind: .keyNotAllowedInSection(.endpoint)),
            ]
        )
    }

    @Test
    func rejectsPeersThatShareAPublicKey() throws {
        let result = parse(Self.interfaceSection + Self.peerSection + Self.peerSection)

        #expect(
            result.issues == [
                ConfigurationIssue(line: 7, kind: .duplicatePeerPublicKey(try SampleKeys.firstPeerPublicKey()))
            ])
    }

    @Test
    func reportsStructuralProblems() {
        let result = parse(
            ["Address = 10.0.0.2/32", "[Mystery]", "Anything = goes"] + Self.interfaceSection + ["not a pair"]
                + Self.peerSection)

        #expect(
            result.issues == [
                ConfigurationIssue(line: 1, kind: .keyOutsideSection("Address")),
                ConfigurationIssue(line: 2, kind: .unknownSection("Mystery")),
                ConfigurationIssue(line: 7, kind: .malformedLine),
            ]
        )
    }

    @Test
    func turnsConfigurationWarningsIntoIssuesAtTheRelevantSection() throws {
        let result = parse(Self.interfaceSection + ["[Peer]", "PublicKey = \(SampleKeys.firstPeerPublicKeyText)"])

        #expect(
            result.issues == [
                ConfigurationIssue(
                    line: 4, kind: .configurationWarning(.peerWithoutAllowedIPs(try SampleKeys.firstPeerPublicKey())))
            ]
        )
        #expect(result.configuration != nil)
    }

    @Test
    func rejectsConfigurationsLargerThanTheLimit() {
        let oversized = String(repeating: "#", count: WgQuickConfigurationParser.maximumConfigurationSize + 1)

        #expect(
            WgQuickConfigurationParser.parse(oversized).issues == [
                ConfigurationIssue(line: nil, kind: .configurationTooLarge)
            ])
    }

    private func parse(_ lines: [String]) -> WgQuickParsingResult {
        WgQuickConfigurationParser.parse(lines.joined(separator: "\n"))
    }
}
