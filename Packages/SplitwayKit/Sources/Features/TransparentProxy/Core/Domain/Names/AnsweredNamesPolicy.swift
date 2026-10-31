import Foundation

public struct AnsweredNamesPolicy: Sendable, Hashable {
    private static let attosecondsPerSecond = 1e18

    public static let standard = AnsweredNamesPolicy(
        trustedMinimumRetention: .seconds(60),
        maximumRetention: .seconds(10 * 60),
        capacity: 1_024
    )

    public let minimumRetention: Duration
    public let maximumRetention: Duration
    public let capacity: Int

    public init(minimumRetention: Duration, maximumRetention: Duration, capacity: Int) throws(RelayPolicyError) {
        guard minimumRetention > .zero else { throw .nonPositiveTimeout }
        guard maximumRetention >= minimumRetention else { throw .retentionOutOfOrder }
        guard capacity > 0 else { throw .nonPositiveCapacity }
        self.init(trustedMinimumRetention: minimumRetention, maximumRetention: maximumRetention, capacity: capacity)
    }

    private init(trustedMinimumRetention: Duration, maximumRetention: Duration, capacity: Int) {
        minimumRetention = trustedMinimumRetention
        self.maximumRetention = maximumRetention
        self.capacity = capacity
    }

    func retention(forTimeToLive timeToLive: UInt32) -> TimeInterval {
        Self.seconds(of: min(max(.seconds(Int(timeToLive)), minimumRetention), maximumRetention))
    }

    var minimumRetentionInterval: TimeInterval {
        Self.seconds(of: minimumRetention)
    }

    private static func seconds(of duration: Duration) -> TimeInterval {
        TimeInterval(duration.components.seconds) + TimeInterval(duration.components.attoseconds) / attosecondsPerSecond
    }
}
