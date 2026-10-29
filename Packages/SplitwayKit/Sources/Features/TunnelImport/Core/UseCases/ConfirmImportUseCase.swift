import TunnelLibrary

public struct ConfirmImportUseCase: Sendable {
    private let importTunnels: ImportTunnelsUseCase

    public init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore) {
        importTunnels = ImportTunnelsUseCase(records: records, secrets: secrets)
    }

    public func execute(_ candidates: [ImportPreviewCandidate]) async throws(TunnelLibraryError) -> ImportReport {
        try await importTunnels.execute(candidates.compactMap(\.importCandidate))
    }
}
