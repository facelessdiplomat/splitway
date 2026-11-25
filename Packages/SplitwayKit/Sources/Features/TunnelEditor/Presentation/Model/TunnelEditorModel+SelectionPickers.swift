import AppRouting
import ApplicationCatalogPresentation
import ServiceCatalogPresentation

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

    public var canChooseServices: Bool {
        servicePickerActions != nil && routing.selectedMode == .selectedServices
    }

    public func chooseServices() {
        guard canChooseServices, let servicePickerActions else { return }
        servicePicker = ServicePickerModel(
            selection: routing.serviceSelection,
            configuration: currentDraft.validation.configuration,
            actions: servicePickerActions
        ) { [routing] selection in
            routing.setServices(selection)
        }
    }

    public func finishChoosingServices() {
        servicePicker = nil
    }
}
