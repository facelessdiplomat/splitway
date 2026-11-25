import ControlWidgets
import Foundation

struct TunnelControlFailure: Error, CustomLocalizedStringResourceConvertible {
    let reason: TunnelControlError

    init(_ reason: TunnelControlError) {
        self.reason = reason
    }

    var localizedStringResource: LocalizedStringResource {
        switch reason {
        case .vpnConfigurationMissing: "Connect a tunnel in Splitway once, then use this control."
        case .action(let error): TunnelShortcutFailure(error).localizedStringResource
        }
    }
}
