public protocol RunningWireGuardDevice: Sendable {
    func apply(_ configuration: UAPIConfiguration) throws(TunnelEngineError)
    func runtimeStatistics() throws(TunnelEngineError) -> RuntimeStatistics
    func bumpSockets() throws(TunnelEngineError)
    func stop()
}
