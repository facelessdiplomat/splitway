import SwiftUI
import TunnelLibrary

struct TunnelDetailScreen: View {
    private let row: TunnelRow
    private let toggleConnection: @MainActor () -> Void
    @State private var model: TunnelDetailModel

    init(
        tunnel: Tunnel,
        row: TunnelRow,
        statistics: TunnelStatisticsPolling,
        toggleConnection: @escaping @MainActor () -> Void
    ) {
        self.row = row
        self.toggleConnection = toggleConnection
        _model = State(initialValue: TunnelDetailModel(tunnel: tunnel, polling: statistics))
    }

    var body: some View {
        TunnelDetailView(
            row: row,
            peers: model.peers,
            statisticsProblem: model.statisticsProblem,
            hasUnansweredFirstHandshake: model.hasUnansweredFirstHandshake,
            toggleConnection: toggleConnection
        )
        .task(id: row.status.reportsStatistics) {
            await model.trackStatistics(isTunnelRunning: row.status.reportsStatistics)
        }
    }
}
