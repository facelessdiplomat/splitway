import TunnelEngine

extension TCPFlowRelay: UserspaceConnectionReceiver {
    public func receive(_ bytes: UnsafeRawBufferPointer) {
        deliverToApp(bytes)
    }

    public func finish(_ error: UserspaceNetworkError?) {
        endFromTunnel(with: error)
    }
}
