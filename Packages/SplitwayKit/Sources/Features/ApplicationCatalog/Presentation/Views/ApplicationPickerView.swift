import ApplicationCatalog
import DesignSystemPresentation
import SwiftUI
import UniformTypeIdentifiers

public struct ApplicationPickerView: View {
    private static let addableTypes: [UTType] = [.applicationBundle, .unixExecutable]
    private static let minimumWidth: CGFloat = 480
    private static let minimumHeight: CGFloat = 520

    @Bindable private var model: ApplicationPickerModel
    private let done: @MainActor () -> Void
    @State private var isAddingFiles = false

    public init(model: ApplicationPickerModel, done: @escaping @MainActor () -> Void) {
        self.model = model
        self.done = done
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker(selection: $model.filter) {
                    ForEach(ApplicationCatalogFilter.allCases, id: \.self) { filter in
                        filter.title.tag(filter)
                    }
                } label: {
                    Text("Show", bundle: .module)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding()
                applicationList
            }
            .navigationTitle(Text("Apps Through the Tunnel", bundle: .module))
            .searchable(text: $model.searchText, prompt: Text("Search Apps", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingFiles = true
                    } label: {
                        Label {
                            Text("Add Tool…", bundle: .module)
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
        }
        .frame(minWidth: Self.minimumWidth, minHeight: Self.minimumHeight)
        .fileImporter(
            isPresented: $isAddingFiles,
            allowedContentTypes: Self.addableTypes,
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let files) = result else { return }
            add(files)
        }
        .alert(Text("Can’t Add This File", bundle: .module), isPresented: isShowingRejectedFile) {
            Button(role: .cancel) {
                model.dismissRejectedFile()
            } label: {
                Text("OK", bundle: .module)
            }
        } message: {
            Text("“\(model.rejectedFileName ?? "")” is not an app or a command-line tool.", bundle: .module)
        }
        .task {
            await model.load()
        }
    }

    private var applicationList: some View {
        List(model.rows) { row in
            ApplicationPickerRowView(row: row, iconLoader: model.iconLoader) { isSelected in
                Task.immediate { await model.setSelected(isSelected, path: row.id) }
            }
        }
        .overlay {
            if model.isLoading {
                ProgressView()
            } else if model.rows.isEmpty {
                EmptyStateView(
                    Text("No Apps", bundle: .module),
                    systemImage: "app.dashed",
                    message: Text("Drag an app here or add a command-line tool.", bundle: .module)
                )
            }
        }
        .dropDestination(for: URL.self) { files, _ in
            add(files)
            return true
        }
    }

    private var isShowingRejectedFile: Binding<Bool> {
        Binding {
            model.rejectedFileName != nil
        } set: { isShowing in
            if !isShowing {
                model.dismissRejectedFile()
            }
        }
    }

    private func add(_ files: [URL]) {
        let paths = files.map { file in file.path(percentEncoded: false) }
        Task.immediate { await model.addApplications(at: paths) }
    }
}
