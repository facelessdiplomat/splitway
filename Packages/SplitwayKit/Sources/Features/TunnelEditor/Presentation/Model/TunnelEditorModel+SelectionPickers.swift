import AppRouting
import ApplicationCatalogPresentation

extension TunnelEditorModel {
    public var canChooseApplications: Bool {
        applicationPickerActions != nil && routing.selectedMode == .selectedApplications
    }

    public func chooseApplications() {
        guard canChooseApplications, let applicationPickerActions else { return }
        applicationPicker = ApplicationPickerModel(
            selection: routing.applicationSelection,
            actions: applicationPickerActions
        ) { [routing] selection in
            routing.setApplications(selection)
        }
    }

    public func finishChoosingApplications() {
        applicationPicker = nil
    }
}
