import DesignSystemPresentation
import SwiftUI
import TunnelEditor

struct InterfaceSection: View {
    let model: TunnelEditorModel
    let copyToClipboard: @MainActor (String) -> Void

    var body: some View {
        Section {
            if model.isPrivateKeyRevealed {
                row(.privateKey, Text("Private key", bundle: .module), example: "")
            } else {
                LabeledContent {
                    Button {
                        model.revealPrivateKey()
                    } label: {
                        Text("Show", bundle: .module)
                    }
                } label: {
                    Text("Private key", bundle: .module)
                }
            }
            Button {
                model.generatePrivateKey()
            } label: {
                Label {
                    Text("Generate a new key pair", bundle: .module)
                } icon: {
                    Image(systemName: "key")
                }
            }
            if let publicKey = model.draft.interface.publicKey {
                IdentifierRow(Text("Public key", bundle: .module), identifier: publicKey)
                Button {
                    copyToClipboard(publicKey)
                } label: {
                    Label {
                        Text("Copy public key", bundle: .module)
                    } icon: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
            row(.addresses, Text("Addresses", bundle: .module), example: "10.0.0.2/32")
            row(.listenPort, Text("Listen port", bundle: .module), example: "51820")
            row(.mtu, Text(verbatim: "MTU"), example: "1420")
            row(.dns, Text("DNS servers", bundle: .module), example: "1.1.1.1")
        } header: {
            Text("Interface", bundle: .module)
        }
    }

    private func row(_ field: InterfaceDraftField, _ title: Text, example: String) -> DraftFieldRow {
        DraftFieldRow(model: model, field: .interface(field), title: title, example: example)
    }
}
