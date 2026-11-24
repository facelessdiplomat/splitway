import SwiftUI
import TunnelLibrary

struct TunnelListView: View {
    @Bindable var model: TunnelListModel
    @Binding var selection: TunnelIdentifier?
    @Binding var isSearching: Bool
    let addition: TunnelAdditionOptions
    let export: TunnelExportModel
    let navigation: TunnelLibraryNavigation

    var body: some View {
        List(selection: $selection) {
            ForEach(model.visibleRows) { row in
                TunnelRowView(row: row) {
                    Task.immediate { await model.toggleConnection(of: row) }
                }
                .contextMenu {
                    duplicateButton(for: row)
                    exportButton(for: row)
                    deleteButton(for: row, role: .destructive)
                }
                .swipeActions {
                    deleteButton(for: row, role: nil)
                        .tint(.red)
                    duplicateButton(for: row)
                }
                .modifier(TunnelDeletionConfirmation(model: model, row: row))
            }
            .onMove(perform: reorderAction)
        }
        .searchable(
            text: $model.searchText,
            isPresented: $isSearching,
            prompt: Text("Search Tunnels", bundle: .module)
        )
        .overlay {
            if model.isEmpty {
                TunnelListEmptyStateView(addition: addition)
            } else if model.hasNoSearchResults {
                ContentUnavailableView.search(text: model.searchText)
            }
        }
        .navigationTitle(Text("Tunnels", bundle: .module))
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            TunnelListToolbar(
                addition: addition, export: export, hasTunnels: !model.rows.isEmpty, navigation: navigation)
        }
        #if os(macOS)
            .onDeleteCommand {
                if let row = selection.flatMap({ id in model.row(withID: id) }) {
                    model.requestDeletion(of: row)
                }
            }
        #endif
    }

    private var reorderAction: ((IndexSet, Int) -> Void)? {
        guard model.canReorder else { return nil }
        return { source, destination in
            Task.immediate { await model.move(fromOffsets: source, toOffset: destination) }
        }
    }

    private func duplicateButton(for row: TunnelRow) -> some View {
        Button {
            Task.immediate { await model.duplicate(row) }
        } label: {
            Label {
                Text("Duplicate", bundle: .module)
            } icon: {
                Image(systemName: "plus.square.on.square")
            }
        }
        .disabled(!row.canDuplicate)
    }

    private func exportButton(for row: TunnelRow) -> some View {
        Button {
            export.requestExport(of: row.id, named: row.name)
        } label: {
            Label {
                Text("Export…", bundle: .module)
            } icon: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .disabled(!row.canExport)
    }

    private func deleteButton(for row: TunnelRow, role: ButtonRole?) -> some View {
        Button(role: role) {
            model.requestDeletion(of: row)
        } label: {
            Label {
                Text("Delete", bundle: .module)
            } icon: {
                Image(systemName: "trash")
            }
        }
    }
}
