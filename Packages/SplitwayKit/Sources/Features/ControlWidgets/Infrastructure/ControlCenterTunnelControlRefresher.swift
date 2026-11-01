import ControlWidgets
import WidgetKit

public struct ControlCenterTunnelControlRefresher: TunnelControlRefresher {
    public init() {}

    public func refresh() async {
        ControlCenter.shared.reloadControls(ofKind: TunnelControlKind.identifier)
    }
}
