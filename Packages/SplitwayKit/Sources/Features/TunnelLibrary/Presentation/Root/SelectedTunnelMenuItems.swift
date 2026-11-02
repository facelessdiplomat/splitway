import SwiftUI

struct SelectedTunnelMenuItems: View {
    let actions: SelectedTunnelActions?

    var body: some View {
        Button {
            actions?.toggleConnection()
        } label: {
            connectionTitle
        }
        .keyboardShortcut(.return, modifiers: .command)
        .disabled(actions?.row.canToggleConnection != true)
        Button {
            actions?.edit?()
        } label: {
            Text("Edit Tunnel", bundle: .module)
        }
        .keyboardShortcut("e")
        .disabled(actions?.edit == nil)
        Button {
            actions?.duplicate()
        } label: {
            Text("Duplicate", bundle: .module)
        }
        .keyboardShortcut("d")
        .disabled(actions?.row.canDuplicate != true)
        Button {
            actions?.export()
        } label: {
            Text("Export…", bundle: .module)
        }
        .keyboardShortcut("e", modifiers: [.command, .shift])
        .disabled(actions?.row.canExport != true)
        Button {
            actions?.delete()
        } label: {
            Text("Delete", bundle: .module)
        }
        .keyboardShortcut(.delete, modifiers: .command)
        .disabled(actions == nil)
    }

    private var connectionTitle: Text {
        actions?.row.isConnectionActive == true
            ? Text("Disconnect", bundle: .module)
            : Text("Connect", bundle: .module)
    }
}
