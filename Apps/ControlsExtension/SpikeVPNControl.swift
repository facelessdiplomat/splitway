import AppIntents
import SwiftUI
import WidgetKit

struct SpikeVPNControl: ControlWidget {
    static let kind = "com.facelessdiplomat.splitway.spike-vpn"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: SpikeVPNValueProvider()) { isActive in
            ControlWidgetToggle("Splitway", isOn: isActive, action: SpikeVPNIntent()) { isOn in
                Label(isOn ? "On" : "Off", systemImage: "network")
            }
        }
        .displayName("Splitway VPN")
    }
}
