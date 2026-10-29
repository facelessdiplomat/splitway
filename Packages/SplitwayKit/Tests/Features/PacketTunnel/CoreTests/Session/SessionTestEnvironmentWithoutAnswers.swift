import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

enum SessionTestEnvironmentWithoutAnswers {
    static func configuration() throws -> TunnelConfiguration {
        let fixture = WgQuickFixtures.minimal.replacingOccurrences(of: "vpn.example.com", with: "missing.example.com")
        return try #require(WgQuickConfigurationParser.parse(fixture).configuration)
    }
}
