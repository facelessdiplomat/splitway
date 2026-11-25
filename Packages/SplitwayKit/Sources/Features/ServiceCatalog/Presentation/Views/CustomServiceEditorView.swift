import DesignSystemPresentation
import SwiftUI

struct CustomServiceEditorView: View {
    private static let entriesMinimumHeight: CGFloat = 88

    @Bindable var model: CustomServiceEditorModel
    let done: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(text: $model.name, prompt: Text("Work", bundle: .module)) {
                        Text("Service name", bundle: .module)
                    }
                    .accessibilityLabel(Text("Service name", bundle: .module))
                } header: {
                    Text("Name", bundle: .module)
                }
                Section {
                    entriesEditor(text: $model.domainsText, label: Text("Domains", bundle: .module))
                    ForEach(model.invalidDomains, id: \.self) { entry in
                        problem(Text("“\(entry)” is not a domain name.", bundle: .module))
                    }
                } header: {
                    Text("Domains", bundle: .module)
                } footer: {
                    Text("One per line, for example example.com. Subdomains are included.", bundle: .module)
                }
                Section {
                    entriesEditor(text: $model.networksText, label: Text("Networks", bundle: .module))
                    ForEach(model.invalidNetworks, id: \.self) { entry in
                        problem(Text("“\(entry)” is not a network. Use a form like 10.0.0.0/8.", bundle: .module))
                    }
                } header: {
                    Text("Networks", bundle: .module)
                } footer: {
                    Text("Optional. One per line, for example 203.0.113.0/24.", bundle: .module)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: done) {
                        Text("Cancel", bundle: .module)
                    }
                    .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task.immediate { await model.save() }
                    } label: {
                        Text("Save", bundle: .module)
                    }
                    .keyboardShortcut("s")
                    .disabled(!model.canSave)
                }
            }
            .alert(Text("Can’t Save the Service", bundle: .module), isPresented: isShowingFailure) {
                Button(role: .cancel) {
                    model.dismissSaveFailure()
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Splitway couldn’t change your services. Try again.", bundle: .module)
            }
        }
    }

    private var title: Text {
        model.isNewService ? Text("New Service", bundle: .module) : Text("Edit Service", bundle: .module)
    }

    private var isShowingFailure: Binding<Bool> {
        Binding {
            model.saveFailure != nil
        } set: { isShowing in
            if !isShowing {
                model.dismissSaveFailure()
            }
        }
    }

    private func entriesEditor(text: Binding<String>, label: Text) -> some View {
        TextEditor(text: text)
            .frame(minHeight: Self.entriesMinimumHeight)
            .plainTextInput()
            .accessibilityLabel(label)
    }

    private func problem(_ message: Text) -> some View {
        Label {
            message
        } icon: {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
        .font(.subheadline)
    }
}
