public protocol WireGuardDeviceEngine: Sendable {
    func startDevice(
        tunnelFileDescriptor: Int32,
        configuration: UAPIConfiguration
    ) throws(TunnelEngineError) -> any RunningWireGuardDevice
}
