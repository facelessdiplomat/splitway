import TunnelEngine

public actor TunnelRuntimeRegistry {
    public private(set) var currentNetwork: (any RunningUserspaceNetwork)?

    public init() {}

    public func register(_ network: any RunningUserspaceNetwork) {
        currentNetwork = network
    }

    public func unregister() {
        currentNetwork = nil
    }
}
