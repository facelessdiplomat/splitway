import Darwin
import Testing
import TunnelConfiguration
import TunnelCoreAdapter
import TunnelEngine

@Suite
struct TunnelCoreWireGuardEngineTests {
    private let engine = TunnelCoreWireGuardEngine()

    @Test
    func reportsAClosedDescriptorAsAnUnavailableTunnelInterface() throws {
        let configuration = try Self.uapiConfiguration()

        #expect(throws: TunnelEngineError.tunnelInterfaceUnavailable) {
            try engine.startDevice(tunnelFileDescriptor: -1, configuration: configuration)
        }
    }

    @Test
    func rejectsAFileThatIsNotATunnelInterfaceAndKeepsItOpen() throws {
        let configuration = try Self.uapiConfiguration()
        let descriptor = open("/dev/null", O_RDONLY)
        try #require(descriptor >= 0)
        defer { close(descriptor) }

        #expect(throws: TunnelEngineError.tunnelInterfaceUnavailable) {
            try engine.startDevice(tunnelFileDescriptor: descriptor, configuration: configuration)
        }
        #expect(fcntl(descriptor, F_GETFD) != -1)
    }

    private static func uapiConfiguration() throws -> UAPIConfiguration {
        let text = "[Interface]\nPrivateKey = \(PrivateKey.generate().base64EncodedText)\n"
        let configuration = try #require(WgQuickConfigurationParser.parse(text).configuration)
        return UAPIConfigurationEncoder.encode(configuration, resolvedEndpoints: [:])
    }
}
