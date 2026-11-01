import AppRoutingPresentation
import DesignSystemPresentation
import SwiftUI
import TunnelConnection
import TunnelConnectionPresentation

struct TunnelDetailView: View {
    let row: TunnelRow
    let peers: [PeerStatisticsRow]
    let statisticsProblem: RuntimeStatisticsError?
    let hasUnansweredFirstHandshake: Bool
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
            if hasUnansweredFirstHandshake {
                Section {
                    UnansweredHandshakeWarning()
                }
            }
            if let failure = row.status.failure {
                Section {
                    VStack(alignment: .leading) {
                        Text(failure.explanation.title)
                            .font(.headline)
                        Text(failure.explanation.message)
                            .foregroundStyle(.supportingText)
                    }
                }
            }
            if !row.routedApplicationNames.isEmpty {
                Section {
                    ForEach(Array(row.routedApplicationNames.enumerated()), id: \.offset) { _, name in
                        Text(verbatim: name)
                    }
                } header: {
                    Text("Apps through the tunnel", bundle: .module)
                }
            }
            if !row.routedServiceNames.isEmpty {
                Section {
                    ForEach(Array(row.routedServiceNames.enumerated()), id: \.offset) { _, name in
                        Text(verbatim: name)
                    }
                } header: {
                    Text("Services through the tunnel", bundle: .module)
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
