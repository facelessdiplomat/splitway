import SwiftUI
import TunnelLibrary

struct TunnelListAlertActions: View {
    let alert: TunnelListAlert
    let model: TunnelListModel
    let editTunnel: @MainActor (Tunnel) -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        switch alert.suggestedAction {
        case .openSettings:
            #if os(iOS)
                if let settings = URL(string: UIApplication.openSettingsURLString) {
                    Button {
                        model.dismissAlert()
                        openURL(settings)
                    } label: {
                        Text("Open Settings", bundle: .module)
                    }
                }
            #endif
        case .editTunnel:
            if let tunnel = alert.tunnelID.flatMap({ id in model.tunnel(withID: id) }) {
                Button {
                    model.dismissAlert()
                    editTunnel(tunnel)
                } label: {
                    Text("Edit Tunnel", bundle: .module)
                }
            }
        case .none:
            EmptyView()
        }
        Button(role: .cancel) {
            model.dismissAlert()
        } label: {
            Text("OK", bundle: .module)
        }
    }
}
