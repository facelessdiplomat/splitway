import TransparentProxy

public struct FixedNetworkPathMTU: NetworkPathMTUReader {
    private let value: Int?

    public init(_ value: Int?) {
        self.value = value
    }

    public func currentPathMTU() -> Int? {
        value
    }
}
