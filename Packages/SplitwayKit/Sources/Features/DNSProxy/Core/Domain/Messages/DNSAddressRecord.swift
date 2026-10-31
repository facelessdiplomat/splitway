import SharedKernel

public struct DNSAddressRecord: Sendable, Hashable {
    public let address: IPAddress
    public let timeToLive: UInt32

    public init(address: IPAddress, timeToLive: UInt32) {
        self.address = address
        self.timeToLive = timeToLive
    }
}
