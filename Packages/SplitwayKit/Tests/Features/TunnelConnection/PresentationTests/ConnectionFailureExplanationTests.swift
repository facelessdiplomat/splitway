import Foundation
import Testing
import TunnelConnection
import TunnelConnectionPresentation

@Suite
struct ConnectionFailureExplanationTests {
    struct Expectation: Sendable {
        let failure: ConnectionFailure
        let message: String
        let action: ConnectionFailureAction
    }

    private static let expectations: [Expectation] = [
        Expectation(
            failure: .permissionDenied,
            message: "Splitway isn’t allowed to add a VPN configuration. Allow it in Settings, then try again.",
            action: .none
        ),
        Expectation(
            failure: .systemConfigurationUnavailable,
            message: "The system VPN configuration couldn’t be read or saved. Try again or restart the device.",
            action: .none
        ),
        Expectation(
            failure: .startRejected,
            message: "The system refused to start the tunnel. Make sure no other VPN is connecting.",
            action: .none
        ),
        Expectation(
            failure: .configurationUnavailable,
            message: "The tunnel configuration couldn’t be read. Edit the tunnel or import it again.",
            action: .editTunnel
        ),
        Expectation(
            failure: .routingModeUnsupported,
            message: "Only All traffic works in this version. Choose it in the tunnel’s routing settings.",
            action: .editTunnel
        ),
        Expectation(
            failure: .extensionUnavailable,
            message:
                "Splitway’s network extension isn’t running. Allow it in System Settings › General › "
                + "Login Items & Extensions, then try again.",
            action: .none
        ),
        Expectation(
            failure: .networkSettingsRejected,
            message: "The system rejected the tunnel addresses, routes or DNS servers. Check them in the editor.",
            action: .editTunnel
        ),
        Expectation(
            failure: .endpointUnresolvable,
            message: "The server in Endpoint couldn’t be found. Check the endpoint and your connection.",
            action: .editTunnel
        ),
        Expectation(
            failure: .engineFailed(.configurationRejected),
            message: "WireGuard couldn’t use this configuration. Check the keys and the allowed IPs.",
            action: .editTunnel
        ),
        Expectation(
            failure: .engineFailed(.socketsUnavailable),
            message: "WireGuard stopped unexpectedly. Try connecting again.",
            action: .none
        ),
        Expectation(
            failure: .unknown,
            message: "Something went wrong while connecting. Try again in a moment.",
            action: .none
        ),
    ]

    @Test(arguments: expectations)
    func explainsEveryFailureAndSuggestsWhatToDo(_ expectation: Expectation) {
        let explanation = expectation.failure.explanation

        #expect(String(localized: explanation.message) == expectation.message)
        #expect(explanation.suggestedAction == expectation.action)
    }

    @Test
    func givesEveryFailureItsOwnTitle() {
        let titles = Self.expectations.map { expectation in String(localized: expectation.failure.explanation.title) }

        #expect(Set(titles).count == titles.count)
    }
}
