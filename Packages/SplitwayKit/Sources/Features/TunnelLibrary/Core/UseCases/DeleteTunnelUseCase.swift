public struct DeleteTunnelUseCase: Sendable {
    private let persistence: TunnelPersistence
    private let activityProbe: any TunnelActivityProbe

    public init(
        records: any TunnelRecordRepository,
        secrets: any TunnelSecretStore,
        activityProbe: any TunnelActivityProbe
    ) {
        persistence = TunnelPersistence(records: records, secrets: secrets)
        self.activityProbe = activityProbe
    }

    public func execute(id: TunnelIdentifier) async throws(TunnelLibraryError) {
        var records = try await persistence.records.loadRecords()
        let index = try TunnelRecordAccess.index(of: id, in: records)
        try await stopIfActive(id)
        let previousText = try? await persistence.configurationText(for: id)
        try await persistence.deleteConfigurationText(for: id)
        records.remove(at: index)
        do {
            try await persistence.records.saveRecords(records)
        } catch {
            await persistence.restoreConfigurationText(previousText, for: id)
            throw error
        }
    }

    private func stopIfActive(_ tunnel: TunnelIdentifier) async throws(TunnelLibraryError) {
        guard await activityProbe.isActive(tunnel) else { return }
        do {
            try await activityProbe.stop(tunnel)
        } catch {
            throw .activeTunnelCouldNotBeStopped
        }
    }
}
