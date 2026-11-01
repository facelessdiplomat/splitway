import DesignSystemPresentation
import SwiftUI

struct LoginItemSection: View {
    let model: LoginItemModel

    var body: some View {
        Section {
            Toggle(isOn: isEnabled) {
                Text("Open at Login", bundle: .module)
            }
            if model.needsApproval {
                Text("Allow Splitway to open at login in System Settings.", bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(.supportingText)
                Button {
                    Task.immediate { await model.openSystemSettings() }
                } label: {
                    Text("Open Login Items Settings…", bundle: .module)
                }
            }
        } header: {
            Text("General", bundle: .module)
                .foregroundStyle(.supportingText)
        }
        .task { await model.load() }
        .alert(Text("Couldn’t Change Opening at Login", bundle: .module), isPresented: isShowingFailure) {
            Button(role: .cancel) {
                model.dismissFailure()
            } label: {
                Text("OK", bundle: .module)
            }
        } message: {
            Text("macOS didn’t accept the change. Try again in System Settings.", bundle: .module)
        }
    }

    private var isEnabled: Binding<Bool> {
        Binding {
            model.isEnabled
        } set: { isEnabled in
            Task.immediate { await model.setEnabled(isEnabled) }
        }
    }

    private var isShowingFailure: Binding<Bool> {
        Binding {
            model.failure != nil
        } set: { isShowing in
            if !isShowing {
                model.dismissFailure()
            }
        }
    }
}
