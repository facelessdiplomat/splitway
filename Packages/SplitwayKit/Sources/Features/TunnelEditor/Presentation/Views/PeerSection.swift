import SwiftUI
import TunnelEditor

struct PeerSection: View {
    let model: TunnelEditorModel
    let peer: PeerDraft

    var body: some View {
        Section {
            row(.publicKey, Text("Public key", bundle: .module), example: "")
            row(.presharedKey, Text("Preshared key", bundle: .module), example: "")
            row(.allowedIPs, Text("Allowed IPs", bundle: .module), example: "0.0.0.0/0, ::/0")
            if model.privateNetworkChoice(forPeer: peer.id) != .notApplicable {
                Toggle(isOn: excludesPrivateNetworks) {
                    Text("Exclude private networks", bundle: .module)
                }
            }
            row(.endpoint, Text("Endpoint", bundle: .module), example: "vpn.example.com:51820")
            row(.persistentKeepalive, Text("Persistent keepalive", bundle: .module), example: "25")
            Button(role: .destructive) {
                model.removePeer(peer.id)
            } label: {
                Text("Delete peer", bundle: .module)
            }
        } header: {
            Text("Peer", bundle: .module)
        }
    }

    private var excludesPrivateNetworks: Binding<Bool> {
        Binding {
            model.privateNetworkChoice(forPeer: peer.id) == .excluded
        } set: { excludes in
            model.setExcludesPrivateNetworks(excludes, forPeer: peer.id)
        }
    }

    private func row(_ field: PeerDraftField, _ title: Text, example: String) -> DraftFieldRow {
        DraftFieldRow(model: model, field: .peer(peer.id, field), title: title, example: example)
    }
}
