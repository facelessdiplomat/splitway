import SwiftUI

struct TunnelListAlertPresentation: ViewModifier {
    let model: TunnelListModel

    func body(content: Content) -> some View {
        content.alert(
            model.alert?.title ?? Text(verbatim: ""),
            isPresented: isPresented,
            presenting: model.alert
        ) { _ in
            Button(role: .cancel) {
                model.dismissAlert()
            } label: {
                Text("OK", bundle: .module)
            }
        } message: { alert in
            alert.message
        }
    }

    private var isPresented: Binding<Bool> {
        Binding {
            model.alert != nil
        } set: { isPresented in
            if !isPresented {
                model.dismissAlert()
            }
        }
    }
}
