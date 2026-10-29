import SwiftUI

struct QRPhotoProblemAlert: ViewModifier {
    let model: QRScannerModel

    func body(content: Content) -> some View {
        content.alert(
            model.photoProblem?.title ?? Text(verbatim: ""),
            isPresented: isShowingProblem,
            presenting: model.photoProblem
        ) { _ in
            Button(role: .cancel) {
                model.dismissPhotoProblem()
            } label: {
                Text("OK", bundle: .module)
            }
        } message: { problem in
            problem.message
        }
    }

    private var isShowingProblem: Binding<Bool> {
        Binding {
            model.photoProblem != nil
        } set: { isPresented in
            if !isPresented {
                model.dismissPhotoProblem()
            }
        }
    }
}
