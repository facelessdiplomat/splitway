import TunnelLibrary

public struct PrepareImportUseCase: Sendable {
    private let loadTunnels: LoadTunnelsUseCase
    private let extractor: ImportPayloadExtractor
    private let fallbackNames: ImportFallbackNames

    public init(
        records: any TunnelRecordRepository,
        secrets: any TunnelSecretStore,
        archiveReader: any ArchiveReader,
        fallbackNames: ImportFallbackNames
    ) {
        loadTunnels = LoadTunnelsUseCase(records: records, secrets: secrets)
        extractor = ImportPayloadExtractor(archiveReader: archiveReader)
        self.fallbackNames = fallbackNames
    }

    public func execute(
        _ payloads: [ImportPayload],
        unreadableFileNames: [String] = []
    ) async throws(TunnelLibraryError) -> ImportPreview {
        let extraction = extractor.extract(payloads)
        let library = try await loadTunnels.execute()
        var evaluator = ImportCandidateEvaluator(library: library, fallbackNames: fallbackNames)
        let candidates = extraction.configurations.map { configuration in evaluator.evaluate(configuration) }
        let unreadableFiles = unreadableFileNames.map { fileName in
            ImportSourceFailure(source: .file(name: fileName), reason: .unreadable)
        }
        return ImportPreview(
            candidates: candidates,
            failures: unreadableFiles + extraction.failures,
            existingNames: library.entries.map(\.name)
        )
    }
}
