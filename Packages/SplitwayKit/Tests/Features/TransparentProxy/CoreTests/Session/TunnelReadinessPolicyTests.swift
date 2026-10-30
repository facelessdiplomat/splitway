import AppRouting
import Foundation
import Testing
import TransparentProxy

@Suite
struct TunnelReadinessPolicyTests {
    private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
    private static let policy = TunnelReadinessPolicy(maximumHandshakeAge: .seconds(180), startupGrace: .seconds(15))

    @Test(arguments: [0.0, 179.0, 180.0])
    func readiesATunnelWithAFreshHandshake(_ handshakeAge: TimeInterval) {
        let moment = Self.start.addingTimeInterval(600)

        let readiness = Self.policy.readiness(
            latestHandshake: moment.addingTimeInterval(-handshakeAge), startedAt: Self.start, at: moment,
            carriesIPv6: true)

        #expect(readiness == .ready(carriesIPv6: true))
    }

    @Test
    func losesATunnelWhoseHandshakeIsStale() {
        let moment = Self.start.addingTimeInterval(600)

        let readiness = Self.policy.readiness(
            latestHandshake: moment.addingTimeInterval(-181), startedAt: Self.start, at: moment, carriesIPv6: false)

        #expect(readiness == .unavailable)
    }

    @Test
    func trustsANewTunnelUntilTheStartupGraceEnds() {
        let early = Self.policy.readiness(
            latestHandshake: nil, startedAt: Self.start, at: Self.start.addingTimeInterval(14), carriesIPv6: false)
        let late = Self.policy.readiness(
            latestHandshake: nil, startedAt: Self.start, at: Self.start.addingTimeInterval(15), carriesIPv6: false)

        #expect(early == .ready(carriesIPv6: false))
        #expect(late == .unavailable)
    }
}
