import SwiftUI
import TunnelLibrary

public struct TunnelLibraryRootView: View {
    private let model: TunnelListModel
    private let statistics: TunnelStatisticsPolling
    private let addition: TunnelAdditionOptions
    private let navigation: TunnelLibraryNavigation
    private let export: TunnelExportModel
    @State private var selection: TunnelIdentifier?

    public init(
        model: TunnelListModel,
        statistics: TunnelStatisticsPolling,
        addition: TunnelAdditionOptions,
        export: TunnelExportModel,
        navigation: TunnelLibraryNavigation
    ) {
        self.model = model
        self.statistics = statistics
        self.addition = addition
        self.navigation = navigation
        self.export = export
    }

    public var body: some View {
        NavigationSplitView {
            TunnelListView(
                model: model,
                selection: $selection,
                addition: addition,
                export: export,
                navigation: navigation
            )
        } detail: {
            detail
        }
        .modifier(TunnelListAlertPresentation(model: model, editTunnel: navigation.editTunnel))
        .modifier(SystemPromptExplanation(model: model))
        .modifier(TunnelExportPresenter(model: export))
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
                            navigation.editTunnel(tunnel)
                        } label: {
                            Label {
                                Text("Edit Tunnel", bundle: .module)
                            } icon: {
                                Image(systemName: "pencil")
                            }
                        }
                        .keyboardShortcut("e")
                    }
                }
            } else {
                TunnelDetailView(row: row, peers: [], statisticsProblem: nil, hasUnansweredFirstHandshake: false) {
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
