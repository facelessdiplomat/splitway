import SwiftUI

struct TunnelEditorView: View {
    let model: TunnelEditorModel
    let copyToClipboard: @MainActor (String) -> Void
    let close: @MainActor () -> Void

    var body: some View {
        Form {
            Section {
                DraftFieldRow(model: model, field: .name, title: Text("Name", bundle: .module), example: "")
            }
            switch model.mode {
            case .form:
                InterfaceSection(model: model, copyToClipboard: copyToClipboard)
                ForEach(model.draft.peers) { peer in
                    PeerSection(model: model, peer: peer)
                }
                Section {
                    Button {
                        model.addPeer()
                    } label: {
                        Label {
                            Text("Add peer", bundle: .module)
                        } icon: {
                            Image(systemName: "plus")
                        }
                    }
                }
            case .text:
                TunnelTextSection(model: model)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(model.isNewTunnel ? Text("New Tunnel", bundle: .module) : Text("Edit Tunnel", bundle: .module))
        .toolbar {
            TunnelEditorToolbar(model: model, close: close)
        }
        .modifier(TunnelRestartConfirmation(model: model))
        .modifier(TunnelEditorFailureAlert(model: model))
    }
}
