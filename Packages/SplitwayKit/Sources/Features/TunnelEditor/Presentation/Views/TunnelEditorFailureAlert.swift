import SwiftUI

struct TunnelEditorFailureAlert: ViewModifier {
    let model: TunnelEditorModel

    func body(content: Content) -> some View {
        content.alert(
            Text("Couldn’t save", bundle: .module),
            isPresented: isShowingFailure,
            presenting: model.failure
        ) { _ in
            Button(role: .cancel) {
                model.dismissFailure()
            } label: {
                Text("OK", bundle: .module)
            }
        } message: { failure in
            switch failure {
            case .saving:
                Text("The tunnel storage couldn’t be read or written. Try again.", bundle: .module)
            case .restarting:
                Text("The tunnel was saved, but it couldn’t reconnect.", bundle: .module)
            }
        }
    }

    private var isShowingFailure: Binding<Bool> {
        Binding {
            model.failure != nil
        } set: { isPresented in
            if !isPresented {
                model.dismissFailure()
            }
        }
    }
}
