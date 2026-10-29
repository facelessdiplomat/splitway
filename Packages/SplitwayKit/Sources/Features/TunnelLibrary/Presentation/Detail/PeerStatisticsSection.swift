import DesignSystemPresentation
import SwiftUI

struct PeerStatisticsSection: View {
    let peer: PeerStatisticsRow

    var body: some View {
        Section {
            IdentifierRow(Text("Public key", bundle: .module), identifier: peer.publicKey)
            if let endpoint = peer.endpoint {
                KeyValueRow(
                    Text("Endpoint", bundle: .module),
                    value: Text(verbatim: endpoint),
                    usesMonospacedValue: true
                )
            }
            if let activity = peer.activity {
                KeyValueRow(Text("Latest handshake", bundle: .module), value: activity.latestHandshake.text)
                KeyValueRow(Text("Received", bundle: .module), value: Self.byteCount(activity.receivedByteCount))
                KeyValueRow(Text("Sent", bundle: .module), value: Self.byteCount(activity.transmittedByteCount))
            }
        } header: {
            Text("Peer", bundle: .module)
                .foregroundStyle(.supportingText)
        }
    }

    private static func byteCount(_ count: UInt64) -> Text {
        Text(Int64(clamping: count), format: .byteCount(style: .file))
    }
}
