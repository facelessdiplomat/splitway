import ControlWidgets
import WidgetKit

struct TunnelControlValueProvider: AppIntentControlValueProvider {
    let composition: ControlsComposition

    func previewValue(configuration: TunnelControlConfigurationIntent) -> TunnelControlContent {
        TunnelControlContent(
            value: TunnelControlValue(isOn: false, tunnelName: configuration.tunnel?.name),
            selection: configuration.tunnel
        )
    }

    func currentValue(configuration: TunnelControlConfigurationIntent) async throws -> TunnelControlContent {
        let snapshot = try await composition.tunnelControl().read.execute(
            selection: configuration.tunnel?.tunnelIdentifier
        )
        return TunnelControlContent(value: snapshot.value, selection: configuration.tunnel)
    }
}
