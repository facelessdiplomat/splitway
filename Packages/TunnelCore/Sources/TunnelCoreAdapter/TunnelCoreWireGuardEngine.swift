import TunnelCoreFramework
import TunnelEngine

public struct TunnelCoreWireGuardEngine: WireGuardDeviceEngine {
    public init() {}

    public func startDevice(
        tunnelFileDescriptor: Int32,
        configuration: UAPIConfiguration
    ) throws(TunnelEngineError) -> any RunningWireGuardDevice {
        var handle: Int32 = 0
        let status = configuration.text.withCString { text in
            tc_fd_tunnel_start(tunnelFileDescriptor, text, &handle)
        }
        try TunnelEngineError.check(status)
        return TunnelCoreWireGuardDevice(handle: handle)
    }
}
