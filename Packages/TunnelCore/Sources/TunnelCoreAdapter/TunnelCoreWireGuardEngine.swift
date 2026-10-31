import TunnelCoreFramework
import TunnelEngine

public struct TunnelCoreWireGuardEngine: WireGuardDeviceEngine {
    private let serviceRouting: TunnelCoreServiceRoutingPlan?

    public init(serviceRouting: TunnelCoreServiceRoutingPlan? = nil) {
        self.serviceRouting = serviceRouting
    }

    public func startDevice(
        tunnelFileDescriptor: Int32,
        configuration: UAPIConfiguration
    ) throws(TunnelEngineError) -> any RunningWireGuardDevice {
        var handle: Int32 = 0
        let status = configuration.text.withCString { text in
            guard let plan = serviceRouting else {
                return tc_fd_tunnel_start(tunnelFileDescriptor, text, &handle)
            }
            return plan.virtualDNS.withCString { virtualDNS in
                plan.fakeNetwork.withCString { fakeNetwork in
                    plan.upstreamDNS.withCString { upstreamDNS in
                        tc_fd_tunnel_start_service_routing(
                            tunnelFileDescriptor, text, virtualDNS, fakeNetwork, upstreamDNS, &handle)
                    }
                }
            }
        }
        try TunnelEngineError.check(status)
        return TunnelCoreWireGuardDevice(handle: handle)
    }
}
