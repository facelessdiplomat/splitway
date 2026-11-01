import NetworkExtension

enum SpikeVPN {
    private static let providerIdentifier = "com.facelessdiplomat.splitway.packet-tunnel"

    static func isActive() async -> Bool {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            let manager = managers.first { manager in isOurs(manager) }
            let status = manager?.connection.status ?? .invalid
            SpikeLog.record("value: managers=\(managers.count) ours=\(manager != nil) status=\(status.rawValue)")
            return [.connected, .connecting, .reasserting].contains(status)
        } catch {
            SpikeLog.record("value: load failed \(error)")
            return false
        }
    }

    static func setActive(_ isActive: Bool) async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            guard let manager = managers.first(where: isOurs) else {
                SpikeLog.record("set \(isActive): no configuration among \(managers.count)")
                return
            }
            if isActive {
                try manager.connection.startVPNTunnel()
            } else {
                manager.connection.stopVPNTunnel()
            }
            SpikeLog.record("set \(isActive): requested, status=\(manager.connection.status.rawValue)")
        } catch {
            SpikeLog.record("set \(isActive): failed \(error)")
        }
    }

    private static func isOurs(_ manager: NETunnelProviderManager) -> Bool {
        (manager.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == providerIdentifier
    }
}
