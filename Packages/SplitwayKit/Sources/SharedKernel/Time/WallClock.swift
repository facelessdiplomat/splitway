import Foundation

public protocol WallClock: Sendable {
    func now() -> Date
}
