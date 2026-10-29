import Foundation

public struct SystemWallClock: WallClock {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
