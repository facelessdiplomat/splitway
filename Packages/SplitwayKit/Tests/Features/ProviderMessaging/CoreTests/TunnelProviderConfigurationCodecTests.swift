import AppRouting
import Foundation
import ProviderMessaging
import Testing
import TunnelLibrary

@Suite
struct TunnelProviderConfigurationCodecTests {
    @Test
    func keepsTheTunnelAndItsPolicyInTheProviderConfiguration() throws {
        let configuration = TunnelProviderConfiguration(
            tunnelID: TunnelIdentifier(),
            routingPolicy: RoutingPolicy(
                mode: .selectedServices(ServiceSelection([try ServiceIdentifier("telegram")])),
                whenTunnelUnavailable: .bypass
            )
        )

        let dictionary = try TunnelProviderConfigurationCodec.dictionary(for: configuration)

        #expect(try TunnelProviderConfigurationCodec.configuration(from: dictionary) == configuration)
    }

    @Test
    func reportsASlotWithoutConfiguration() {
        #expect(throws: TunnelProviderConfigurationError.missing) {
            try TunnelProviderConfigurationCodec.configuration(from: nil)
        }
        #expect(throws: TunnelProviderConfigurationError.missing) {
            try TunnelProviderConfigurationCodec.configuration(from: ["unrelated": 1])
        }
    }

    @Test
    func reportsAConfigurationFromAnotherVersion() {
        let dictionary: [String: Any] = [
            TunnelProviderConfigurationCodec.payloadKey: Data(#"{"protocolVersion":7,"payload":{}}"#.utf8)
        ]

        #expect(throws: TunnelProviderConfigurationError.unsupportedVersion(7)) {
            try TunnelProviderConfigurationCodec.configuration(from: dictionary)
        }
    }

    @Test
    func reportsACorruptedConfiguration() {
        let dictionary: [String: Any] = [TunnelProviderConfigurationCodec.payloadKey: Data("garbage".utf8)]

        #expect(throws: TunnelProviderConfigurationError.malformed) {
            try TunnelProviderConfigurationCodec.configuration(from: dictionary)
        }
    }
}
