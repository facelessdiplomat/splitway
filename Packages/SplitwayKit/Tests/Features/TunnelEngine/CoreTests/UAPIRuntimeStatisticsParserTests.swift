import Foundation
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEngine

@Suite
struct UAPIRuntimeStatisticsParserTests {
    @Test
    func readsTheStatisticsOfEveryPeer() throws {
        let statistics = try UAPIRuntimeStatisticsParser.parse(try Self.deviceResponse())

        #expect(
            statistics.peers == [
                PeerRuntimeStatistics(
                    publicKey: try SampleKeys.firstPeerPublicKey(),
                    receivedByteCount: 10_584,
                    transmittedByteCount: 7_340,
                    latestHandshake: Date(timeIntervalSince1970: 1_793_268_900.5)
                ),
                PeerRuntimeStatistics(
                    publicKey: try SampleKeys.secondPeerPublicKey(),
                    receivedByteCount: 0,
                    transmittedByteCount: 148,
                    latestHandshake: nil
                ),
            ]
        )
    }

    @Test
    func addsUpTheTrafficOfAllPeers() throws {
        let statistics = try UAPIRuntimeStatisticsParser.parse(try Self.deviceResponse())

        #expect(statistics.receivedByteCount == 10_584)
        #expect(statistics.transmittedByteCount == 7_488)
        #expect(statistics.latestHandshake == Date(timeIntervalSince1970: 1_793_268_900.5))
    }

    @Test
    func acceptsAResponseThatEndsWithASuccessfulErrno() throws {
        let statistics = try UAPIRuntimeStatisticsParser.parse(try Self.deviceResponse() + "errno=0\n\n")

        #expect(statistics.peers.count == 2)
    }

    @Test
    func reportsTheErrorTheDeviceReturned() {
        #expect(throws: UAPIResponseError.deviceError(code: 19)) {
            try UAPIRuntimeStatisticsParser.parse("errno=19\n")
        }
    }

    @Test(arguments: ["listen_port", "public_key=zz", "public_key=\(String(repeating: "0", count: 64))\nrx_bytes=-1"])
    func rejectsAMalformedResponse(_ response: String) {
        #expect(throws: UAPIResponseError.malformedResponse) {
            try UAPIRuntimeStatisticsParser.parse(response)
        }
    }

    private static func deviceResponse() throws -> String {
        """
        private_key=\(try SampleKeys.interfacePrivateKey().hexEncodedText)
        listen_port=51820
        public_key=\(try SampleKeys.firstPeerPublicKey().hexEncodedText)
        preshared_key=\(try SampleKeys.presharedKey().hexEncodedText)
        protocol_version=1
        endpoint=[2001:db8::1]:51820
        last_handshake_time_sec=1793268900
        last_handshake_time_nsec=500000000
        tx_bytes=7340
        rx_bytes=10584
        persistent_keepalive_interval=25
        allowed_ip=0.0.0.0/0
        allowed_ip=::/0
        public_key=\(try SampleKeys.secondPeerPublicKey().hexEncodedText)
        preshared_key=\(String(repeating: "0", count: 64))
        protocol_version=1
        last_handshake_time_sec=0
        last_handshake_time_nsec=0
        tx_bytes=148
        rx_bytes=0
        persistent_keepalive_interval=0
        allowed_ip=10.1.0.0/24

        """
    }
}
