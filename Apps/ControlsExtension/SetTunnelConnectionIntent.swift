import AppIntents
import ControlWidgets
import Diagnostics

struct SetTunnelConnectionIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Turn Tunnel On or Off"
    static let isDiscoverable = false

    @Parameter(title: "Tunnel")
    var tunnel: TunnelEntity?

    @Parameter(title: "Connected")
    var value: Bool

    @Dependency
    private var composition: ControlsComposition

    init() {}

    init(tunnel: TunnelEntity?) {
        self.tunnel = tunnel
    }

    func perform() async throws -> some IntentResult {
        let log = composition.log
        let action = value ? "on" : "off"
        do {
            try await composition.tunnelControl().set.execute(isOn: value, selection: tunnel?.tunnelIdentifier)
        } catch {
            log.record(.error, "Control Center could not turn the tunnel \(action): \(error)")
            throw TunnelControlFailure(error)
        }
        log.record(.info, "Control Center turned the tunnel \(action)")
        return .result()
    }
}
