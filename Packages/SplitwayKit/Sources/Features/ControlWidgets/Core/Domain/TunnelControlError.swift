import Shortcuts

public enum TunnelControlError: Error, Sendable, Equatable {
    case vpnConfigurationMissing
    case action(TunnelShortcutError)
}
