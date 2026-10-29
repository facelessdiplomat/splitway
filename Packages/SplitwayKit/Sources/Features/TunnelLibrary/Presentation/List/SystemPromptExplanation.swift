import SwiftUI

struct SystemPromptExplanation: ViewModifier {
    let model: TunnelListModel

    func body(content: Content) -> some View {
        content.alert(Text("Before you connect", bundle: .module), isPresented: isPresented) {
            Button {
                Task.immediate { await model.continueToSystemPrompt() }
            } label: {
                Text("Continue", bundle: .module)
            }
            Button(role: .cancel) {
                model.dismissSystemPromptExplanation()
            } label: {
                Text("Cancel", bundle: .module)
            }
        } message: {
            Text(
                "Your device will ask to add a VPN configuration for Splitway. Allow it to connect.",
                bundle: .module
            )
        }
    }

    private var isPresented: Binding<Bool> {
        Binding {
            model.tunnelAwaitingSystemPrompt != nil
        } set: { _ in
        }
    }
}
