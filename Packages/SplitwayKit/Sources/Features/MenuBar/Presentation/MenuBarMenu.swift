import AppRoutingPresentation
import SwiftUI
import TunnelLibraryPresentation

struct MenuBarMenu: View {
    let model: MenuBarModel

    var body: some View {
        statusLine
        if let routingMode = model.activeTunnel?.routingMode {
            routingMode.title
        }
        Divider()
        if model.hasNoTunnels {
            Text("No tunnels yet", bundle: .module)
            Button {
                model.requestMainWindow()
            } label: {
                Text("Add a Tunnel…", bundle: .module)
            }
        } else {
            ForEach(model.items) { tunnel in
                Toggle(isOn: selection(of: tunnel)) {
                    Text(verbatim: tunnel.name)
                }
                .disabled(!tunnel.isSelectable)
            }
        }
        Divider()
        Button {
            model.requestMainWindow()
        } label: {
            Text("Open Splitway", bundle: .module)
        }
        SettingsLink {
            Text("Settings…", bundle: .module)
        }
        .keyboardShortcut(",")
        Divider()
        Button {
            Task.immediate { await model.quit() }
        } label: {
            Text("Quit Splitway", bundle: .module)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder private var statusLine: some View {
        if let headline = model.headlineTunnel {
            Text("\(Text(verbatim: headline.name)): \(headline.status.title)", bundle: .module)
        } else {
            Text("Not connected", bundle: .module)
        }
    }

    private func selection(of tunnel: MenuBarTunnel) -> Binding<Bool> {
        Binding {
            tunnel.isActive
        } set: { _ in
            Task.immediate { await model.select(tunnel) }
        }
    }
}
