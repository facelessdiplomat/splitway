import SwiftUI

extension View {
    public func systemExtensionAttention(_ model: SystemExtensionWizardModel?, isSuppressed: Bool) -> some View {
        modifier(SystemExtensionAttention(model: model, isSuppressed: isSuppressed))
    }
}
