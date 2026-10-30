import SwiftUI
import TunnelConfigurationPresentation
import UniformTypeIdentifiers

struct TunnelImportPresenter: ViewModifier {
    private static let importableTypes = ImportableFileTypes.types()

    @Bindable var model: TunnelImportModel

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: $model.isPickingFiles,
                allowedContentTypes: Self.importableTypes,
                allowsMultipleSelection: true
            ) { result in
                guard case .success(let files) = result else { return }
                Task.immediate { await model.importFiles(files) }
            }
            .sheet(item: $model.preview) { preview in
                NavigationStack {
                    ImportPreviewView(model: preview)
                }
            }
            .alert(
                model.alert?.title ?? Text(verbatim: ""),
                isPresented: isShowingAlert,
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

    private var isShowingAlert: Binding<Bool> {
        Binding {
            model.alert != nil
        } set: { isPresented in
            if !isPresented {
                model.dismissAlert()
            }
        }
    }
}
