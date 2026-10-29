import SwiftUI
import TunnelLibrary

public struct TunnelLibraryRootView: View {
    private let model: TunnelListModel
    private let statistics: TunnelStatisticsPolling
    private let addition: TunnelAdditionOptions
    private let editTunnel: @MainActor (Tunnel) -> Void
    @State private var selection: TunnelIdentifier?

    public init(
        model: TunnelListModel,
        statistics: TunnelStatisticsPolling,
        addition: TunnelAdditionOptions,
        editTunnel: @escaping @MainActor (Tunnel) -> Void
    ) {
        self.model = model
        self.statistics = statistics
        self.addition = addition
        self.editTunnel = editTunnel
    }

    public var body: some View {
        NavigationSplitView {
            TunnelListView(model: model, selection: $selection, addition: addition)
        } detail: {
            detail
        }
        .task { await model.load() }
        .task { await model.observeConnection() }
    }

    @ViewBuilder
    private var detail: some View {
        if let id = selection, let row = model.row(withID: id) {
            if let tunnel = model.tunnel(withID: id) {
                TunnelDetailScreen(tunnel: tunnel, row: row, statistics: statistics) {
                    toggleConnection(of: row)
                }
                .id(tunnel)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            editTunnel(tunnel)
                        } label: {
                            Text("Edit", bundle: .module)
                        }
                    }
                }
            } else {
                TunnelDetailView(row: row, peers: [], statisticsProblem: nil) {
                    toggleConnection(of: row)
                }
            }
        } else {
            ContentUnavailableView {
                Label {
                    Text("Select a tunnel", bundle: .module)
                } icon: {
                    Image(systemName: "network")
                }
            }
        }
    }

    private func toggleConnection(of row: TunnelRow) {
        Task.immediate { await model.toggleConnection(of: row) }
    }
}
