#if os(macOS)
    import NetworkExtension

    public enum TransparentProxySlot: ProviderSlotKind {
        public static func savedSlots() async -> sending [NEVPNManager] {
            (try? await NETransparentProxyManager.loadAllFromPreferences()) ?? []
        }

        public static func newSlot() -> sending NEVPNManager {
            NETransparentProxyManager()
        }
    }
#endif
