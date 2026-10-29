import SwiftUI
import TunnelLibrary

public struct TunnelLibraryRootView: View {
    private let model: TunnelListModel
    private let addition: TunnelAdditionOptions
    @State private var selection: TunnelIdentifier?

    public init(model: TunnelListModel, addition: TunnelAdditionOptions) {
        self.model = model
        self.addition = addition
    }

    public var body: some View {
        NavigationSplitView {
            TunnelListView(model: model, selection: $selection, addition: addition)
        } detail: {
            if let row = selection.flatMap({ id in model.row(withID: id) }) {
                TunnelDetailView(row: row) {
                    Task.immediate { await model.toggleConnection(of: row) }
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
        .task { await model.load() }
        .task { await model.observeConnection() }
    }
}
