import ControlWidgets

struct TunnelControlContent: Sendable {
    private static let fallbackTitle = "Splitway"

    let value: TunnelControlValue
    let selection: TunnelEntity?

    var title: String {
        value.tunnelName ?? Self.fallbackTitle
    }
}
