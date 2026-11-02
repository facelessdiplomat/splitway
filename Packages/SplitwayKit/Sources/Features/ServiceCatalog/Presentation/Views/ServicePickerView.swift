import DesignSystemPresentation
import ServiceCatalog
import SwiftUI

public struct ServicePickerView: View {
    @Bindable private var model: ServicePickerModel
    private let done: @MainActor () -> Void
    @State private var detailedService: ServiceProfile?
    @State private var isExplainingRouting = false

    public init(model: ServicePickerModel, done: @escaping @MainActor () -> Void) {
        self.model = model
        self.done = done
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isExplainingRouting = true
                    } label: {
                        Label {
                            Text("How It Works and Limitations", bundle: .module)
                        } icon: {
                            Image(systemName: "info.circle")
                        }
                    }
                    ForEach(model.warnings, id: \.self) { warning in
                        Label {
                            warning.message
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        .font(.subheadline)
                    }
                }
                ForEach(model.sections) { section in
                    Section {
                        ForEach(section.rows) { row in
                            ServicePickerRowView(row: row) { isSelected in
                                model.setSelected(isSelected, id: row.id)
                            }
                            .contextMenu { serviceActions(for: row.service) }
                            .swipeActions { serviceActions(for: row.service) }
                        }
                    } header: {
                        section.category.title
                    }
                }
            }
            .overlay { placeholder }
            .navigationTitle(Text("Services Through the Tunnel", bundle: .module))
            .searchable(text: $model.searchText, prompt: Text("Search Services", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        model.addCustomService()
                    } label: {
                        Label {
                            Text("Add Service", bundle: .module)
                        } icon: {
                            Image(systemName: "plus")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: done) {
                        Text("Done", bundle: .module)
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .navigationDestination(item: $detailedService) { service in
                ServiceDetailView(service: service, customServiceActions: customServiceActions(for: service))
            }
            .sheet(item: customServiceEditor) { editor in
                CustomServiceEditorView(model: editor) {
                    model.finishEditingCustomService()
                }
            }
            .sheet(isPresented: $isExplainingRouting) {
                ServiceRoutingExplanationView {
                    isExplainingRouting = false
                }
            }
            .alert(Text("Can’t Delete the Service", bundle: .module), isPresented: isShowingDeletionFailure) {
                Button(role: .cancel) {
                    model.dismissDeletionFailure()
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Splitway couldn’t change your services. Try again.", bundle: .module)
            }
        }
        .task {
            await model.load()
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if model.isLoading {
            ProgressView()
        } else if model.isCatalogUnavailable {
            EmptyStateView(
                Text("Services Unavailable", bundle: .module),
                systemImage: "exclamationmark.triangle",
                message: Text("Splitway couldn’t read the list of services.", bundle: .module)
            )
        } else if model.sections.isEmpty, !model.searchText.isEmpty {
            EmptyStateView(
                Text("No Results", bundle: .module),
                systemImage: "magnifyingglass",
                message: Text("No service matches “\(model.searchText)”.", bundle: .module)
            )
        }
    }

    @ViewBuilder
    private func serviceActions(for service: ServiceProfile) -> some View {
        Button {
            detailedService = service
        } label: {
            Text("Details", bundle: .module)
        }
        if let actions = customServiceActions(for: service) {
            Button(action: actions.edit) {
                Text("Edit", bundle: .module)
            }
            Button(role: .destructive, action: actions.delete) {
                Text("Delete", bundle: .module)
            }
        }
    }

    private func customServiceActions(for service: ServiceProfile) -> CustomServiceActions? {
        guard service.category == .custom else { return nil }
        return CustomServiceActions {
            detailedService = nil
            model.editCustomService(service.id)
        } delete: {
            detailedService = nil
            Task.immediate { await model.deleteCustomService(service.id) }
        }
    }

    private var customServiceEditor: Binding<CustomServiceEditorModel?> {
        Binding {
            model.customServiceEditor
        } set: { editor in
            if editor == nil {
                model.finishEditingCustomService()
            }
        }
    }

    private var isShowingDeletionFailure: Binding<Bool> {
        Binding {
            model.deletionFailure != nil
        } set: { isShowing in
            if !isShowing {
                model.dismissDeletionFailure()
            }
        }
    }
}
