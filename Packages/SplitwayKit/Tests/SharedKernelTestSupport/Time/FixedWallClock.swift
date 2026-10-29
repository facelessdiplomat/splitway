import Foundation
import SharedKernel

public struct FixedWallClock: WallClock {
    private let configuredMoment: Date

    public init(_ configuredMoment: Date) {
        self.configuredMoment = configuredMoment
    }

    public func now() -> Date {
        configuredMoment
    }
}
