public protocol UserspaceNetworkEngine: Sendable {
    func startNetwork(
        configuration: UAPIConfiguration,
        interface: UserspaceNetworkInterface
    ) throws(TunnelEngineError) -> any RunningUserspaceNetwork
}
