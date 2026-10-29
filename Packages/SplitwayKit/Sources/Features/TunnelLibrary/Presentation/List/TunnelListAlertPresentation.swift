import SwiftUI
import TunnelLibrary

struct TunnelListAlertPresentation: ViewModifier {
    let model: TunnelListModel
    let editTunnel: @MainActor (Tunnel) -> Void

    func body(content: Content) -> some View {
        content.alert(
            model.alert?.title ?? Text(verbatim: ""),
            isPresented: isPresented,
            presenting: model.alert
        ) { alert in
            TunnelListAlertActions(alert: alert, model: model, editTunnel: editTunnel)
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
