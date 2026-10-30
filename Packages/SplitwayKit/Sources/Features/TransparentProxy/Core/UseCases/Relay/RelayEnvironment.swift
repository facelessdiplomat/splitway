import Dispatch
import SharedKernel

public struct RelayEnvironment: Sendable {
    public let targetQueue: DispatchQueue
    public let clock: any WallClock

    public init(targetQueue: DispatchQueue, clock: any WallClock) {
        self.targetQueue = targetQueue
        self.clock = clock
    }
}
