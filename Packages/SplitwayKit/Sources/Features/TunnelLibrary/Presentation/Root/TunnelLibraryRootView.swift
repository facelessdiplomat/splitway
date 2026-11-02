import SwiftUI
import TunnelLibrary

public struct TunnelLibraryRootView: View {
    #if os(macOS)
        private static let minimumWindowWidth: CGFloat = 640
        private static let minimumWindowHeight: CGFloat = 440
        private static let minimumSidebarWidth: CGFloat = 250
        private static let idealSidebarWidth: CGFloat = 280
    #endif

    private let model: TunnelListModel
    private let statistics: TunnelStatisticsPolling
    private let addition: TunnelAdditionOptions
    private let navigation: TunnelLibraryNavigation
    private let export: TunnelExportModel
    @State private var selection: TunnelIdentifier?
    @State private var isSearching = false

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
                isSearching: $isSearching,
                addition: addition,
                export: export,
                navigation: navigation
            )
            #if os(macOS)
                .navigationSplitViewColumnWidth(min: Self.minimumSidebarWidth, ideal: Self.idealSidebarWidth)
            #endif
        } detail: {
            detail
        }
        .modifier(TunnelListAlertPresentation(model: model, editTunnel: navigation.editTunnel))
        .modifier(SystemPromptExplanation(model: model))
        .modifier(TunnelExportPresenter(model: export))
        .focusedSceneValue(\.selectedTunnel, selectedTunnelActions)
        .focusedSceneValue(\.tunnelSearch, TunnelSearchActivation { isSearching = true })
        #if os(macOS)
            .frame(minWidth: Self.minimumWindowWidth, minHeight: Self.minimumWindowHeight)
        #endif
        .task { await model.load() }
        .task { await model.observeConnection() }
    }

    private var selectedTunnelActions: SelectedTunnelActions? {
        guard let id = selection, let row = model.row(withID: id) else { return nil }
        return SelectedTunnelActions(
            row: row,
            toggleConnection: { toggleConnection(of: row) },
            edit: editAction(forTunnelWithID: id),
            duplicate: { Task.immediate { await model.duplicate(row) } },
            export: { export.requestExport(of: row.id, named: row.name) },
            delete: { model.requestDeletion(of: row) }
        )
    }

    private func editAction(forTunnelWithID id: TunnelIdentifier) -> (@MainActor () -> Void)? {
        guard let tunnel = model.tunnel(withID: id) else { return nil }
        return { navigation.editTunnel(tunnel) }
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
