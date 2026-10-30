import AppRouting
import Foundation

public struct TunnelReadinessPolicy: Sendable, Hashable {
    public static let standard = TunnelReadinessPolicy(maximumHandshakeAge: .seconds(180), startupGrace: .seconds(15))

    public let maximumHandshakeAge: Duration
    public let startupGrace: Duration

    public init(maximumHandshakeAge: Duration, startupGrace: Duration) {
        self.maximumHandshakeAge = maximumHandshakeAge
        self.startupGrace = startupGrace
    }

    public func readiness(
        latestHandshake: Date?,
        startedAt start: Date,
        at moment: Date,
        carriesIPv6: Bool
    ) -> TunnelReadiness {
        guard let latestHandshake else {
            let sessionAge = Duration.seconds(moment.timeIntervalSince(start))
            return sessionAge < startupGrace ? .ready(carriesIPv6: carriesIPv6) : .unavailable
        }
        let handshakeAge = Duration.seconds(moment.timeIntervalSince(latestHandshake))
        return handshakeAge <= maximumHandshakeAge ? .ready(carriesIPv6: carriesIPv6) : .unavailable
    }
}
