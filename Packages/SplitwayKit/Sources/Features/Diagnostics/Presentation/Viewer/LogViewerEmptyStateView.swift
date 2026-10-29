import DesignSystemPresentation
import SwiftUI

struct LogViewerEmptyStateView: View {
    let state: LogViewerEmptyState

    var body: some View {
        switch state {
        case .noEntries:
            EmptyStateView(
                Text("No entries", bundle: .module),
                systemImage: "doc.text.magnifyingglass",
                message: Text("Entries of the app and the tunnel appear here.", bundle: .module)
            )
        case .noMatchingEntries:
            EmptyStateView(
                Text("No matching entries", bundle: .module),
                systemImage: "line.3.horizontal.decrease.circle",
                message: Text("Change the filter or the search text.", bundle: .module)
            )
        }
    }
}
