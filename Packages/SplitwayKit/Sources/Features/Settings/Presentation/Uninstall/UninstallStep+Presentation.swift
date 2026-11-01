import Foundation
import Settings

extension UninstallStep {
    var title: String {
        switch self {
        case .stopTunnel: String(localized: "the tunnel connection", bundle: .module)
        case .removeVPNConfigurations: String(localized: "VPN configurations", bundle: .module)
        case .removeSecrets: String(localized: "tunnel keys", bundle: .module)
        case .removeLoginItem: String(localized: "opening at login", bundle: .module)
        case .removeAppData: String(localized: "Splitway’s data", bundle: .module)
        case .deactivateSystemExtension: String(localized: "the network extension", bundle: .module)
        }
    }
}
