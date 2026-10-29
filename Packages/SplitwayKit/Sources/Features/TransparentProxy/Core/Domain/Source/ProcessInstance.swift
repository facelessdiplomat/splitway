public struct ProcessInstance: Sendable, Hashable {
    public let identifier: Int32
    public let version: UInt32

    public init(identifier: Int32, version: UInt32) {
        self.identifier = identifier
        self.version = version
    }
}
