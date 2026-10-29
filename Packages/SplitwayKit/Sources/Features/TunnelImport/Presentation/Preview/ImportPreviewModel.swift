import Observation
import TunnelImport
import TunnelLibrary

@MainActor
@Observable
public final class ImportPreviewModel: Identifiable {
    public private(set) var rows: [ImportPreviewRow] = []
    public private(set) var summary: ImportSummary?
    public private(set) var isImporting = false
    public private(set) var importError: TunnelLibraryError?
    public let failures: [ImportSourceFailure]

    private var selection: ImportSelection
    private var typedNames: [Int: String] = [:]
    private let confirmImport: ConfirmImportUseCase
    private let didImport: @MainActor () async -> Void

    init(
        preview: ImportPreview,
        confirmImport: ConfirmImportUseCase,
        didImport: @escaping @MainActor () async -> Void
    ) {
        selection = ImportSelection(preview: preview)
        failures = preview.failures
        self.confirmImport = confirmImport
        self.didImport = didImport
        rebuildRows()
    }

    public var canImport: Bool {
        selection.hasSelection && summary == nil && !isImporting
            && !rows.contains { row in row.isSelected && row.hasInvalidName }
    }

    public func setSelected(_ isSelected: Bool, for row: ImportPreviewRow) {
        selection.setSelected(isSelected, at: row.id)
        rebuildRows()
    }

    public func rename(_ row: ImportPreviewRow, to text: String) {
        typedNames[row.id] = text
        if let name = try? TunnelName(text) {
            selection.rename(at: row.id, to: name)
        }
        rebuildRows()
    }

    public func confirm() async {
        guard canImport else { return }
        isImporting = true
        defer { isImporting = false }
        do {
            let report = try await confirmImport.execute(selection)
            summary = ImportSummary(
                importedCount: report.importedTunnels.count,
                totalCount: selection.preview.candidates.count + failures.count
            )
            await didImport()
        } catch {
            importError = error
        }
    }

    public func dismissImportError() {
        importError = nil
    }

    private func rebuildRows() {
        let importNames = selection.importNames
        rows = selection.preview.candidates.enumerated().map { index, candidate in
            let typedName = typedNames[index]
            return ImportPreviewRow(
                id: index,
                source: candidate.source,
                name: typedName ?? selection.chosenName(of: index).description,
                importName: importNames[index]?.description,
                isSelected: selection.isSelected(index),
                isImportable: candidate.isImportable,
                hasInvalidName: typedName.map { text in (try? TunnelName(text)) == nil } ?? false,
                errors: candidate.errors,
                warnings: candidate.warnings,
                alreadyImportedAs: candidate.alreadyImportedAs?.description
            )
        }
    }
}
