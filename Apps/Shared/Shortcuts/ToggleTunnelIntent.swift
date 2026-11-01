import AppIntents
import Shortcuts

struct ToggleTunnelIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Tunnel"

    static var description: IntentDescription {
        IntentDescription("Connects a Splitway tunnel, or disconnects it if it is connected.")
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Toggle \(\.$tunnel)")
    }

    @Parameter(title: "Tunnel")
    var tunnel: TunnelEntity

    @Dependency
    private var shortcuts: TunnelShortcutActions

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let outcome: TunnelShortcutOutcome
        do {
            outcome = try await shortcuts.toggle.execute(tunnel.tunnelIdentifier)
        } catch {
            throw TunnelShortcutFailure(error)
        }
        switch outcome {
        case .connected:
            return .result(dialog: "Connecting \(tunnel.name).")
        case .disconnected:
            return .result(dialog: "\(tunnel.name) is disconnected.")
        }
    }
}
