import SwiftUI

struct LogViewerDialogs: ViewModifier {
    let model: LogViewerModel
    @Binding var isConfirmingClearing: Bool

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                Text("Clear the log?", bundle: .module),
                isPresented: $isConfirmingClearing,
                titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    Task.immediate { await model.clear() }
                } label: {
                    Text("Clear", bundle: .module)
                }
            } message: {
                Text("All entries of the app and the tunnel will be removed.", bundle: .module)
            }
            .alert(Text("The log is unavailable", bundle: .module), isPresented: isShowingProblem) {
                Button(role: .cancel) {
                    model.dismissProblem()
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("The log file couldn’t be read or written.", bundle: .module)
            }
            .modifier(LogExportPresenter(model: model))
    }

    private var isShowingProblem: Binding<Bool> {
        Binding {
            model.problem != nil
        } set: { isPresented in
            if !isPresented {
                model.dismissProblem()
            }
        }
    }
}
