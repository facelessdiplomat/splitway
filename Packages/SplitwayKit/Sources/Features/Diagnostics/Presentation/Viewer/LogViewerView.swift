import Diagnostics
import SwiftUI

struct LogViewerView: View {
    let model: LogViewerModel
    let close: @MainActor () -> Void
    @State private var isConfirmingClearing = false

    var body: some View {
        List {
            ForEach(Array(model.entries.enumerated()), id: \.offset) { _, entry in
                LogEntryRow(entry: entry)
            }
        }
        .overlay {
            if let emptyState = model.emptyState {
                LogViewerEmptyStateView(state: emptyState)
            }
        }
        #if os(macOS)
            .safeAreaInset(edge: .top) {
                HStack {
                    LogViewerActionButton(action: .export, model: model, confirmClearing: confirmClearing)
                    LogViewerActionButton(action: .sendReport, model: model, confirmClearing: confirmClearing)
                    Spacer()
                    LogViewerActionButton(action: .clear, model: model, confirmClearing: confirmClearing)
                }
                .padding()
            }
        #endif
        .searchable(text: searchText)
        .navigationTitle(Text("Log", bundle: .module))
        .toolbar {
            LogViewerToolbar(model: model, close: close, confirmClearing: confirmClearing)
        }
        .task { await model.followUpdates() }
        .modifier(LogViewerDialogs(model: model, isConfirmingClearing: $isConfirmingClearing))
        .modifier(CrashReportPresenter(model: model))
    }

    private func confirmClearing() {
        isConfirmingClearing = true
    }

    private var searchText: Binding<String> {
        Binding {
            model.filter.searchText
        } set: { text in
            model.setSearchText(text)
        }
    }
}
