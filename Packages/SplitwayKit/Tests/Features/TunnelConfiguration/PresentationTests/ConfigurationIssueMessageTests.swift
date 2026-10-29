import Foundation
import Testing
import TunnelConfiguration
import TunnelConfigurationPresentation
import TunnelConfigurationTestSupport

@Suite
struct ConfigurationIssueMessageTests {
    private static let messagesByIssue: [(ConfigurationIssueKind, String)] = [
        (.configurationTooLarge, "The configuration is too large."),
        (.malformedLine, "This line is not a section, a key with a value or a comment."),
        (.keyOutsideSection("Address"), "Address is outside any section."),
        (.unknownSection("Proxy"), "Unknown section [Proxy]."),
        (.missingInterfaceSection, "The [Interface] section is missing."),
        (.multipleInterfaceSections, "There is more than one [Interface] section."),
        (.unknownKey("Colour"), "Unknown key Colour."),
        (.keyNotAllowedInSection(.endpoint), "Endpoint is not allowed in this section."),
        (.duplicateKey(.mtu), "MTU appears more than once."),
        (.invalidValue(.mtu, .mtu(.outOfRange)), "The value of MTU is invalid."),
        (.amneziaWGNotSupported("Jc"), "Jc belongs to AmneziaWG, which is not supported yet."),
        (.unsupportedWgQuickKey("PostUp"), "PostUp is a wg-quick setting and will be ignored."),
        (.missingPrivateKey, "The private key is missing."),
        (.missingPeerPublicKey, "A peer has no public key."),
        (.configurationWarning(.noPeers), "The configuration has no peers."),
        (.configurationWarning(.interfaceWithoutAddresses), "The interface has no addresses."),
    ]

    @Test(arguments: messagesByIssue)
    func explainsEveryIssue(kind: ConfigurationIssueKind, message: String) {
        #expect(String(localized: kind.message) == message)
    }

    @Test
    func explainsIssuesAboutPeerKeys() throws {
        let key = try SampleKeys.firstPeerPublicKey()

        #expect(
            String(localized: ConfigurationIssueKind.duplicatePeerPublicKey(key).message)
                == "Two peers have the same public key."
        )
        #expect(
            String(localized: TunnelConfigurationWarning.peerUsesInterfacePublicKey(key).message)
                == "A peer uses the public key of this interface."
        )
        #expect(
            String(localized: TunnelConfigurationWarning.peerWithoutAllowedIPs(key).message)
                == "A peer has no allowed IPs."
        )
    }
}
