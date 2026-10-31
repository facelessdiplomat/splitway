public struct RunningProcess: Sendable, Hashable {
    public let identifier: Int32
    public let startTime: UInt64

    public init(identifier: Int32, startTime: UInt64) {
        self.identifier = identifier
        self.startTime = startTime
    }
}
