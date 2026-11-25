import AppRoutingPresentation
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
                RoutingSection(
                    model: model.routing,
                    excludesPrivateNetworks: excludesPrivateNetworks,
                    chooseApplications: chooseApplications,
                    chooseServices: chooseServices
                )
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
                RoutingSection(
                    model: model.routing,
                    excludesPrivateNetworks: nil,
                    chooseApplications: chooseApplications,
                    chooseServices: chooseServices
                )
            }
        }
        .formStyle(.grouped)
        .navigationTitle(model.isNewTunnel ? Text("New Tunnel", bundle: .module) : Text("Edit Tunnel", bundle: .module))
        .toolbar {
            TunnelEditorToolbar(model: model, close: close)
        }
        .modifier(TunnelRestartConfirmation(model: model))
        .modifier(TunnelEditorFailureAlert(model: model))
        .modifier(ApplicationPickerSheet(model: model))
        .modifier(ServicePickerSheet(model: model))
    }

    private var chooseApplications: (@MainActor () -> Void)? {
        guard model.canChooseApplications else { return nil }
        return { model.chooseApplications() }
    }

    private var chooseServices: (@MainActor () -> Void)? {
        guard model.canChooseServices else { return nil }
        return { model.chooseServices() }
    }

    private var excludesPrivateNetworks: Binding<Bool>? {
        guard model.privateNetworkChoice() != .notApplicable else { return nil }
        return Binding {
            model.privateNetworkChoice() == .excluded
        } set: { excludes in
            model.setExcludesPrivateNetworks(excludes)
        }
    }
}
