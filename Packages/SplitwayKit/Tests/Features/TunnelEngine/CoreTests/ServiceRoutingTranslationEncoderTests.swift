import Foundation
import SharedKernel
import Testing
import TunnelEngine

@Suite
struct ServiceRoutingTranslationEncoderTests {
    private static let engineAcceptedFixtures = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "../../../../../TunnelCore/go/servicerouting/testdata")
        .standardized

    @Test
    func encodesATranslationExactlyAsTheEngineReadsIt() throws {
        let translation = ServiceRoutingTranslation(
            virtualResolver: try IPAddress("198.18.0.2"),
            upstreamResolver: try IPAddress("10.64.0.1"),
            fakeIPv4Network: try IPNetwork("198.18.0.0/15"),
            fakeIPv6Network: try IPNetwork("2001:2::/48")
        )

        let document = try ServiceRoutingTranslationEncoder.document(for: translation)

        #expect(document == (try Self.fixture(named: "plan.json")))
    }

    @Test
    func leavesOutTheFakeIPv6NetworkOfATunnelWithoutIPv6() throws {
        let translation = ServiceRoutingTranslation(
            virtualResolver: try IPAddress("198.19.0.2"),
            upstreamResolver: try IPAddress("1.1.1.1"),
            fakeIPv4Network: try IPNetwork("198.19.0.0/16"),
            fakeIPv6Network: nil
        )

        let document = try ServiceRoutingTranslationEncoder.document(for: translation)

        #expect(document == (try Self.fixture(named: "plan-without-ipv6.json")))
    }

    private static func fixture(named name: String) throws -> String {
        try String(contentsOf: engineAcceptedFixtures.appending(path: name), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
