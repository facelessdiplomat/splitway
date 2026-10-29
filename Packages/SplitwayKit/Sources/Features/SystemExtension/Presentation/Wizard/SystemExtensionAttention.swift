import SwiftUI

struct SystemExtensionAttention: ViewModifier {
    private static let minimumWidth: CGFloat = 420

    let model: SystemExtensionWizardModel?
    let isSuppressed: Bool

    func body(content: Content) -> some View {
        content.sheet(isPresented: isShowing) {
            if let model {
                SystemExtensionWizardView(model: model)
                    .frame(minWidth: Self.minimumWidth)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                model.postpone()
                            } label: {
                                Text("Later", bundle: .module)
                            }
                        }
                    }
            }
        }
    }

    private var isShowing: Binding<Bool> {
        Binding {
            !isSuppressed && model?.needsAttention == true
        } set: { isPresented in
            if !isPresented {
                model?.postpone()
            }
        }
    }
}
