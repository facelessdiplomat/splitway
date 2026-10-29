import TunnelConfiguration

struct TunnelPersistence: Sendable {
    let records: TunnelRecordAccess
    let secrets: any TunnelSecretStore

    init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore) {
        self.records = TunnelRecordAccess(repository: records)
        self.secrets = secrets
    }

    func configurationText(for tunnel: TunnelIdentifier) async throws(TunnelLibraryError) -> String {
        do {
            return try await secrets.loadConfigurationText(for: tunnel)
        } catch {
            throw .storage(error)
        }
    }

    func saveConfigurationText(_ text: String, for tunnel: TunnelIdentifier) async throws(TunnelLibraryError) {
        do {
            try await secrets.saveConfigurationText(text, for: tunnel)
        } catch {
            throw .storage(error)
        }
    }

    func deleteConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelLibraryError) {
        do {
            try await secrets.deleteConfigurationText(for: tunnel)
        } catch {
            throw .storage(error)
        }
    }

    func tunnel(for record: TunnelRecord) async throws(TunnelLibraryError) -> Tunnel {
        let text = try await configurationText(for: record.id)
        guard let configuration = WgQuickConfigurationParser.parse(text).configuration else {
            throw .unreadableConfiguration(record.id)
        }
        return Tunnel(
            id: record.id, name: record.name, configuration: configuration, routingPolicy: record.routingPolicy)
    }

    func add(_ tunnel: Tunnel, after existingRecords: [TunnelRecord]) async throws(TunnelLibraryError) {
        try await saveConfigurationText(WgQuickConfigurationSerializer.serialize(tunnel.configuration), for: tunnel.id)
        do {
            try await records.saveRecords(existingRecords + [TunnelRecord(tunnel)])
        } catch {
            try? await secrets.deleteConfigurationText(for: tunnel.id)
            throw error
        }
    }

    func restoreConfigurationText(_ text: String?, for tunnel: TunnelIdentifier) async {
        guard let text else { return }
        try? await secrets.saveConfigurationText(text, for: tunnel)
    }
}
