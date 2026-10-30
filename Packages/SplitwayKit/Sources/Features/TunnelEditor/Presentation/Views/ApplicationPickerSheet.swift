import ApplicationCatalogPresentation
import SwiftUI

struct ApplicationPickerSheet: ViewModifier {
    let model: TunnelEditorModel

    func body(content: Content) -> some View {
        content
            .sheet(item: picker) { picker in
                ApplicationPickerView(model: picker) {
                    model.finishChoosingApplications()
                }
            }
    }

    private var picker: Binding<ApplicationPickerModel?> {
        Binding {
            model.applicationPicker
        } set: { picker in
            if picker == nil {
                model.finishChoosingApplications()
            }
        }
    }
}
