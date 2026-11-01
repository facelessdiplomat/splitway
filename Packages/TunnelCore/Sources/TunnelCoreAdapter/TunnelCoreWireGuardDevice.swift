import TunnelCoreFramework
import TunnelEngine

final class TunnelCoreWireGuardDevice: RunningTunnelInterfaceDevice {
    private let handle: Int32

    init(handle: Int32) {
        self.handle = handle
    }

    deinit {
        stop()
    }

    func apply(_ configuration: UAPIConfiguration) throws(TunnelEngineError) {
        let status = configuration.text.withCString { text in tc_tunnel_update_config(handle, text) }
        try TunnelEngineError.check(status)
    }

    func applyServiceRouting(_ translation: ServiceRoutingTranslation) throws(TunnelEngineError) {
        let document = try ServiceRoutingTranslationEncoder.document(for: translation)
        let status = document.withCString { text in tc_fd_tunnel_set_service_routing(handle, text) }
        try TunnelEngineError.check(status)
    }

    func runtimeStatistics() throws(TunnelEngineError) -> RuntimeStatistics {
        var response: UnsafeMutablePointer<CChar>?
        try TunnelEngineError.check(tc_tunnel_get_config(handle, &response))
        guard let response else { throw .internalFailure }
        defer { tc_free(response) }
        do {
            return try UAPIRuntimeStatisticsParser.parse(String(cString: response))
        } catch {
            throw .unreadableStatistics
        }
    }

    func bumpSockets() throws(TunnelEngineError) {
        try TunnelEngineError.check(tc_tunnel_bump_sockets(handle))
    }

    func stop() {
        _ = tc_tunnel_stop(handle)
    }
}
