import AppIntents
import Shortcuts

struct ConnectTunnelIntent: AppIntent {
    static let title: LocalizedStringResource = "Connect Tunnel"

    static var description: IntentDescription {
        IntentDescription("Connects a Splitway tunnel.")
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Connect \(\.$tunnel)")
    }

    @Parameter(title: "Tunnel")
    var tunnel: TunnelEntity

    @Dependency
    private var shortcuts: TunnelShortcutActions

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            try await shortcuts.connect.execute(tunnel.tunnelIdentifier)
        } catch {
            throw TunnelShortcutFailure(error)
        }
        return .result(dialog: "Connecting \(tunnel.name).")
    }
}
