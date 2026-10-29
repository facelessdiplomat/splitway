import PacketTunnel

struct FakeTunnelInterfaceLocator: TunnelInterfaceLocator {
    let log: SessionEventLog
    let descriptor: Int32?

    func tunnelFileDescriptor() -> Int32? {
        if descriptor != nil {
            log.record(.locatedInterface)
        }
        return descriptor
    }
}
