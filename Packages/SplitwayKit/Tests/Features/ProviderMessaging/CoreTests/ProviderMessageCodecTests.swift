import AppRouting
import Foundation
import ProviderMessaging
import Testing
import TunnelConfigurationTestSupport
import TunnelEngine

@Suite
struct ProviderMessageCodecTests {
    private let codec = ProviderMessageCodec()

    @Test(arguments: try requests())
    func roundTripsEveryRequest(_ request: ProviderRequest) throws {
        #expect(try codec.decodeRequest(from: codec.encode(request)) == request)
    }

    @Test(arguments: try responses())
    func roundTripsEveryResponse(_ response: ProviderResponse) throws {
        #expect(try codec.decodeResponse(from: codec.encode(response)) == response)
    }

    @Test
    func reportsTheProtocolVersionOfAnUnsupportedMessage() {
        let message = Data(#"{"protocolVersion":99,"payload":{"healthCheck":{}}}"#.utf8)

        #expect(throws: ProviderMessageCodingError.unsupportedProtocolVersion(found: 99)) {
            try codec.decodeRequest(from: message)
        }
        #expect(throws: ProviderMessageCodingError.unsupportedProtocolVersion(found: 99)) {
            try codec.decodeResponse(from: message)
        }
    }

    @Test(arguments: [
        "",
        "not json",
        "[]",
        #"{"payload":{"healthCheck":{}}}"#,
        #"{"protocolVersion":1}"#,
        #"{"protocolVersion":1,"payload":{"launchMissiles":{}}}"#,
    ])
    func rejectsCorruptedMessagesWithoutCrashing(_ text: String) {
        #expect(throws: ProviderMessageCodingError.malformedMessage) {
            try codec.decodeRequest(from: Data(text.utf8))
        }
    }

    @Test
    func rejectsStatisticsWithAnInvalidPeerKey() {
        let peer = #"{"publicKey":"not-a-key","receivedByteCount":1,"transmittedByteCount":2}"#
        let payload = #"{"runtimeStatistics":{"statistics":{"peers":["# + peer + "]}}}"
        let message = Data(#"{"protocolVersion":1,"payload":"#.utf8) + Data((payload + "}").utf8)

        #expect(throws: ProviderMessageCodingError.malformedMessage) {
            try codec.decodeResponse(from: message)
        }
    }

    private static func requests() throws -> [ProviderRequest] {
        [
            .runtimeStatistics,
            .applyRoutingPolicy(
                policy: RoutingPolicy(
                    mode: .selectedApplications(
                        ApplicationSelection([
                            try ApplicationIdentity(kind: .commandLineTool, displayName: "curl", path: "/usr/bin/curl")
                        ])
                    ),
                    whenTunnelUnavailable: .bypass
                )
            ),
            .healthCheck,
        ]
    }

    private static func responses() throws -> [ProviderResponse] {
        let statistics = RuntimeStatistics(peers: [
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
        ])
        return [
            .runtimeStatistics(statistics: statistics),
            .routingPolicyApplied,
            .health(isTunnelRunning: true),
            .failure(reason: .unsupportedProtocolVersion),
            .failure(reason: .malformedRequest),
            .failure(reason: .tunnelNotRunning),
            .failure(reason: .routingPolicyRejected),
            .failure(reason: .internalFailure),
        ]
    }
}
