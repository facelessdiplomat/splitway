import Foundation
import TunnelConfiguration

extension TunnelConfigurationWarning {
    public var message: LocalizedStringResource {
        switch self {
        case .noPeers: .moduleResource("The configuration has no peers.")
        case .interfaceWithoutAddresses: .moduleResource("The interface has no addresses.")
        case .peerUsesInterfacePublicKey: .moduleResource("A peer uses the public key of this interface.")
        case .peerWithoutAllowedIPs: .moduleResource("A peer has no allowed IPs.")
        }
    }
}
