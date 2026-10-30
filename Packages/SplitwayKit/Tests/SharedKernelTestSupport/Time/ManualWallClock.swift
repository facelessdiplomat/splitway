import Foundation
import SharedKernel
import Synchronization

public final class ManualWallClock: WallClock {
    private let moment: Mutex<Date>

    public init(_ start: Date) {
        moment = Mutex(start)
    }

    public func now() -> Date {
        moment.withLock { moment in moment }
    }

    public func advance(by duration: Duration) {
        let seconds =
            TimeInterval(duration.components.seconds)
            + TimeInterval(duration.components.attoseconds) / 1e18
        moment.withLock { moment in moment = moment.addingTimeInterval(seconds) }
    }
}
