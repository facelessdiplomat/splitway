import SwiftUI

struct LogViewerActionButton: View {
    enum Action {
        case export
        case sendReport
        case clear
    }

    let action: Action
    let model: LogViewerModel
    let confirmClearing: @MainActor () -> Void

    var body: some View {
        switch action {
        case .export:
            Button {
                Task.immediate { await model.prepareExport() }
            } label: {
                Label {
                    Text("Export Log", bundle: .module)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .disabled(model.isLogEmpty)
        case .sendReport:
            Button {
                model.showCrashReport()
            } label: {
                Label {
                    Text("Send Report…", bundle: .module)
                } icon: {
                    Image(systemName: "paperplane")
                }
            }
        case .clear:
            Button(role: .destructive) {
                confirmClearing()
            } label: {
                Label {
                    Text("Clear Log", bundle: .module)
                } icon: {
                    Image(systemName: "trash")
                }
            }
            .disabled(model.isLogEmpty)
        }
    }
}
