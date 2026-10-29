import SwiftUI

struct TunnelRestartConfirmation: ViewModifier {
    let model: TunnelEditorModel

    func body(content: Content) -> some View {
        content.confirmationDialog(
            Text("Restart the tunnel?", bundle: .module),
            isPresented: isConfirmingRestart,
            titleVisibility: .visible
        ) {
            Button {
                Task.immediate { await model.confirmRestart() }
            } label: {
                Text("Save and Restart", bundle: .module)
            }
        } message: {
            Text(
                "The tunnel is connected. It will disconnect and connect again with the new settings.",
                bundle: .module
            )
        }
    }

    private var isConfirmingRestart: Binding<Bool> {
        Binding {
            model.isConfirmingRestart
        } set: { isPresented in
            if !isPresented {
                model.cancelRestart()
            }
        }
    }
}
