import ControlWidgetsInfrastructure
import SwiftUI
import WidgetKit

struct TunnelControl: ControlWidget {
    private static let symbolName = "network.badge.shield.half.filled"

    private let composition = ControlsComposition(configuration: AppConfiguration(bundle: .main))

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: TunnelControlKind.identifier,
            provider: TunnelControlValueProvider(composition: composition)
        ) { content in
            ControlWidgetToggle(
                content.title,
                isOn: content.value.isOn,
                action: SetTunnelConnectionIntent(tunnel: content.selection)
            ) { isOn in
                Label(isOn ? "On" : "Off", systemImage: Self.symbolName)
            }
        }
        .displayName("Splitway Tunnel")
        .description("Connects or disconnects a Splitway tunnel.")
    }
}
