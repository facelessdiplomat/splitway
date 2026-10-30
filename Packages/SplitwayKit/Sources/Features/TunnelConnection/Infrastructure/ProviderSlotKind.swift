import NetworkExtension

public protocol ProviderSlotKind: Sendable {
    static func savedSlots() async -> sending [NEVPNManager]
    static func newSlot() -> sending NEVPNManager
}
