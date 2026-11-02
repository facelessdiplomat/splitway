import DesignSystemPresentation
import SwiftUI

struct CrashReportView: View {
    let model: CrashReportModel
    let close: @MainActor () -> Void

    var body: some View {
        content
            .navigationTitle(Text("Send Report", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        close()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .task { await model.prepare() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .preparing:
            ProgressView()
        case .ready(let report):
            CrashReportContents(report: report)
        case .unavailable:
            EmptyStateView(
                Text("The report couldn’t be prepared", bundle: .module),
                systemImage: "exclamationmark.triangle",
                message: Text("The log or the crash reports couldn’t be read.", bundle: .module)
            )
        }
    }
}
