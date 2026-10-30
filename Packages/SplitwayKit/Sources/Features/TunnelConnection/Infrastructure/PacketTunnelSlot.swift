import NetworkExtension

public enum PacketTunnelSlot: ProviderSlotKind {
    public static func savedSlots() async -> sending [NEVPNManager] {
        (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
    }

    public static func newSlot() -> sending NEVPNManager {
        NETunnelProviderManager()
    }
}
