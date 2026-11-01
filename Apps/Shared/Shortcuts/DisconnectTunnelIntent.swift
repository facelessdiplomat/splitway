import AppIntents
import Shortcuts

struct DisconnectTunnelIntent: AppIntent {
    static let title: LocalizedStringResource = "Disconnect Tunnel"

    static var description: IntentDescription {
        IntentDescription("Disconnects a Splitway tunnel if it is connected.")
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Disconnect \(\.$tunnel)")
    }

    @Parameter(title: "Tunnel")
    var tunnel: TunnelEntity

    @Dependency
    private var shortcuts: TunnelShortcutActions

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            try await shortcuts.disconnect.execute(tunnel.tunnelIdentifier)
        } catch {
            throw TunnelShortcutFailure(error)
        }
        return .result(dialog: "\(tunnel.name) is disconnected.")
    }
}
