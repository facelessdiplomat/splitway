import SwiftUI

struct TunnelDeletionConfirmation: ViewModifier {
    let model: TunnelListModel
    let row: TunnelRow

    func body(content: Content) -> some View {
        let request = model.deletionRequest(for: row.id)
        content.confirmationDialog(
            request?.title ?? Text(verbatim: ""),
            isPresented: isPresented,
            titleVisibility: .visible,
            presenting: request
        ) { request in
            Button(role: .destructive) {
                Task.immediate { await model.confirmDeletion(of: request) }
            } label: {
                Text("Delete", bundle: .module)
            }
        } message: { request in
            request.consequences
        }
    }

    private var isPresented: Binding<Bool> {
        Binding {
            model.deletionRequest(for: row.id) != nil
        } set: { isPresented in
            if !isPresented {
                model.cancelDeletion()
            }
        }
    }
}
