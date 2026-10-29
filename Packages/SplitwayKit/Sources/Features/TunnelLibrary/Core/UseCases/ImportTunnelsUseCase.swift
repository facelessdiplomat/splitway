import TunnelConfiguration

public struct ImportCandidate: Sendable, Equatable {
    public let proposedName: TunnelName
    public let configuration: TunnelConfiguration

    public init(proposedName: TunnelName, configuration: TunnelConfiguration) {
        self.proposedName = proposedName
        self.configuration = configuration
    }
}

public struct ImportFailure: Sendable, Equatable {
    public let candidate: ImportCandidate
    public let error: TunnelLibraryError
}

public struct ImportReport: Sendable, Equatable {
    public let importedTunnels: [Tunnel]
    public let failures: [ImportFailure]
}

public struct ImportTunnelsUseCase: Sendable {
    private let persistence: TunnelPersistence

    public init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore) {
        persistence = TunnelPersistence(records: records, secrets: secrets)
    }

    public func execute(_ candidates: [ImportCandidate]) async throws(TunnelLibraryError) -> ImportReport {
        var records = try await persistence.records.loadRecords()
        var importedTunnels: [Tunnel] = []
        var failures: [ImportFailure] = []
        for candidate in candidates {
            let tunnel = Tunnel(
                name: UniqueTunnelNameResolver.uniqueName(for: candidate.proposedName, takenNames: records.map(\.name)),
                configuration: candidate.configuration
            )
            do {
                try await persistence.add(tunnel, after: records)
                records.append(TunnelRecord(tunnel))
                importedTunnels.append(tunnel)
            } catch {
                failures.append(ImportFailure(candidate: candidate, error: error))
            }
        }
        return ImportReport(importedTunnels: importedTunnels, failures: failures)
    }
}
