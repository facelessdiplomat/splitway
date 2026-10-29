import Foundation
import TunnelConnection

extension ConnectionFailure {
    public var explanation: ConnectionFailureExplanation {
        systemExplanation ?? tunnelExplanation
    }

    private var systemExplanation: ConnectionFailureExplanation? {
        switch self {
        case .permissionDenied:
            ConnectionFailureExplanation(
                title: .moduleResource("VPN permission needed"),
                message: .moduleResource(
                    "Splitway isn’t allowed to add a VPN configuration. Allow it in Settings, then try again."
                ),
                suggestedAction: .openSettings
            )
        case .systemConfigurationUnavailable:
            ConnectionFailureExplanation(
                title: .moduleResource("VPN configuration unavailable"),
                message: .moduleResource(
                    "The system VPN configuration couldn’t be read or saved. Try again or restart the device."
                ),
                suggestedAction: .none
            )
        case .startRejected:
            ConnectionFailureExplanation(
                title: .moduleResource("The tunnel didn’t start"),
                message: .moduleResource(
                    "The system refused to start the tunnel. Make sure no other VPN is connecting."
                ),
                suggestedAction: .none
            )
        case .configurationUnavailable:
            ConnectionFailureExplanation(
                title: .moduleResource("Configuration missing"),
                message: .moduleResource(
                    "The tunnel configuration couldn’t be read. Edit the tunnel or import it again."
                ),
                suggestedAction: .editTunnel
            )
        case .routingModeUnsupported:
            ConnectionFailureExplanation(
                title: .moduleResource("Routing mode not supported yet"),
                message: .moduleResource(
                    "Only All traffic works in this version. Choose it in the tunnel’s routing settings."
                ),
                suggestedAction: .editTunnel
            )
        default:
            nil
        }
    }

    private var tunnelExplanation: ConnectionFailureExplanation {
        switch self {
        case .networkSettingsRejected:
            ConnectionFailureExplanation(
                title: .moduleResource("Network settings rejected"),
                message: .moduleResource(
                    "The system rejected the tunnel addresses, routes or DNS servers. Check them in the editor."
                ),
                suggestedAction: .editTunnel
            )
        case .endpointUnresolvable:
            ConnectionFailureExplanation(
                title: .moduleResource("Server not found"),
                message: .moduleResource(
                    "The server in Endpoint couldn’t be found. Check the endpoint and your connection."
                ),
                suggestedAction: .editTunnel
            )
        case .engineFailed(.configurationRejected):
            ConnectionFailureExplanation(
                title: .moduleResource("Configuration rejected"),
                message: .moduleResource(
                    "WireGuard couldn’t use this configuration. Check the keys and the allowed IPs."
                ),
                suggestedAction: .editTunnel
            )
        case .engineFailed:
            ConnectionFailureExplanation(
                title: .moduleResource("The tunnel stopped"),
                message: .moduleResource("WireGuard stopped unexpectedly. Try connecting again."),
                suggestedAction: .none
            )
        default:
            ConnectionFailureExplanation(
                title: .moduleResource("Couldn’t connect"),
                message: .moduleResource("Something went wrong while connecting. Try again in a moment."),
                suggestedAction: .none
            )
        }
    }
}
