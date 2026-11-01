import Foundation
import Shortcuts
import TunnelConnectionPresentation

struct TunnelShortcutFailure: Error, CustomLocalizedStringResourceConvertible {
    let reason: TunnelShortcutError

    init(_ reason: TunnelShortcutError) {
        self.reason = reason
    }

    var localizedStringResource: LocalizedStringResource {
        switch reason {
        case .libraryUnavailable: "Splitway couldn’t read its tunnels."
        case .tunnelNotFound: "This tunnel is no longer in Splitway."
        case .tunnelUnreadable: "Splitway couldn’t read this tunnel’s configuration. Open Splitway to fix it."
        case .connectionFailed(let failure): failure.explanation.message
        case .disconnectionFailed: "The tunnel didn’t disconnect. Try again in Splitway."
        }
    }
}
