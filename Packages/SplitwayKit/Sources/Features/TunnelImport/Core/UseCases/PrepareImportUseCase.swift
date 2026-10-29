import TunnelLibrary

public struct PrepareImportUseCase: Sendable {
    private let loadTunnels: LoadTunnelsUseCase
    private let extractor: ImportPayloadExtractor
    private let fallbackName: TunnelName

    public init(
        records: any TunnelRecordRepository,
        secrets: any TunnelSecretStore,
        archiveReader: any ArchiveReader,
        fallbackName: TunnelName
    ) {
        loadTunnels = LoadTunnelsUseCase(records: records, secrets: secrets)
        extractor = ImportPayloadExtractor(archiveReader: archiveReader)
        self.fallbackName = fallbackName
    }

    public func execute(_ payloads: [ImportPayload]) async throws(TunnelLibraryError) -> ImportPreview {
        let extraction = extractor.extract(payloads)
        var evaluator = ImportCandidateEvaluator(library: try await loadTunnels.execute(), fallbackName: fallbackName)
        let candidates = extraction.configurations.map { configuration in evaluator.evaluate(configuration) }
        return ImportPreview(candidates: candidates, failures: extraction.failures)
    }
}
