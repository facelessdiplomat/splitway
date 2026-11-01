import TunnelConfiguration

extension TunnelMTU {
    init(interface: InterfaceConfiguration) {
        self = interface.mtu.map(TunnelMTU.fixed) ?? .pathMTUWithOverhead(bytes: Self.wireGuardOverheadBytes)
    }
}
