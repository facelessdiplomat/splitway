import AppRoutingPresentation
import DesignSystemPresentation
import SwiftUI
import TunnelConnection

struct TunnelDetailView: View {
    let row: TunnelRow
    let peers: [PeerStatisticsRow]
    let statisticsProblem: RuntimeStatisticsError?
    let toggleConnection: @MainActor () -> Void

    var body: some View {
        Form {
            Section {
                TunnelConnectionToggle(row: row, toggleConnection: toggleConnection) {
                    Text("Connection", bundle: .module)
                }
                HStack {
                    Text("Status", bundle: .module)
                    Spacer()
                    StatusBadge(row.status.title, tone: row.status.tone)
                }
                .alignmentGuide(.listRowSeparatorLeading) { dimensions in dimensions[.leading] }
                if let connectedSince = row.status.connectedSince {
                    KeyValueRow(Text("Connected for", bundle: .module), value: Text(connectedSince, style: .timer))
                }
                if let routingMode = row.routingMode {
                    KeyValueRow(Text("Routing", bundle: .module), value: routingMode.title)
                }
            } footer: {
                if statisticsProblem != nil {
                    Text("Statistics are unavailable right now.", bundle: .module)
                }
            }
            ForEach(peers) { peer in
                PeerStatisticsSection(peer: peer)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text(verbatim: row.name))
    }
}
