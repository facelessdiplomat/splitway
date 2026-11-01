public protocol RunningTunnelInterfaceDevice: RunningWireGuardDevice {
    func applyServiceRouting(_ translation: ServiceRoutingTranslation) throws(TunnelEngineError)
}
