import SwiftUI

struct TunnelExportProblemAlert: ViewModifier {
    let model: TunnelExportModel

    func body(content: Content) -> some View {
        content.alert(
            model.problem?.title ?? Text(verbatim: ""),
            isPresented: isPresented,
            presenting: model.problem
        ) { _ in
            Button(role: .cancel) {
                model.dismissProblem()
            } label: {
                Text("OK", bundle: .module)
            }
        } message: { problem in
            problem.message
        }
    }

    private var isPresented: Binding<Bool> {
        Binding {
            model.problem != nil
        } set: { isPresented in
            if !isPresented {
                model.dismissProblem()
            }
        }
    }
}
