import Foundation
import Testing
import TunnelConfiguration
import TunnelConfigurationPresentation

@Suite
struct ConfigurationValueErrorMessageTests {
    private static let messagesByError: [(ConfigurationValueError, String)] = [
        (.key(.malformedBase64), "Enter a 44-character base64 key."),
        (.network(.prefixLengthOutOfRange), "Enter addresses like 10.0.0.2/32, separated by commas."),
        (.port(.outOfRange), "Enter a port from 1 to 65535."),
        (.mtu(.outOfRange), "Enter an MTU from 576 to 9000."),
        (.persistentKeepalive(.outOfRange), "Enter seconds from 1 to 65535, or 0 to turn it off."),
        (.endpoint(.missingPort), "Enter a host and port, like vpn.example.com:51820."),
        (.dns(.invalidEntry("x y")), "Enter DNS servers or search domains, separated by commas."),
    ]

    @Test(arguments: messagesByError)
    func explainsEveryInvalidValue(error: ConfigurationValueError, message: String) {
        #expect(String(localized: error.message) == message)
    }
}
