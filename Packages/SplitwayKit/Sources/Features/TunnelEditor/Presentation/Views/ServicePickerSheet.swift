import ServiceCatalogPresentation
import SwiftUI

struct ServicePickerSheet: ViewModifier {
    let model: TunnelEditorModel

    func body(content: Content) -> some View {
        content
            .sheet(item: picker) { picker in
                ServicePickerView(model: picker) {
                    model.finishChoosingServices()
                }
            }
    }

    private var picker: Binding<ServicePickerModel?> {
        Binding {
            model.servicePicker
        } set: { picker in
            if picker == nil {
                model.finishChoosingServices()
            }
        }
    }
}
