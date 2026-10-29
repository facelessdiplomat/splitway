import AppRouting
import TunnelConfiguration

public struct UpdateTunnelUseCase: Sendable {
    private let persistence: TunnelPersistence

    public init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore) {
        persistence = TunnelPersistence(records: records, secrets: secrets)
    }

    public func execute(
        id: TunnelIdentifier,
        configuration: TunnelConfiguration,
        routingPolicy: RoutingPolicy
    ) async throws(TunnelLibraryError) -> Tunnel {
        var records = try await persistence.records.loadRecords()
        let index = try TunnelRecordAccess.index(of: id, in: records)
        let updatedTunnel = Tunnel(
            id: id,
            name: records[index].name,
            configuration: configuration,
            routingPolicy: routingPolicy
        )
        let previousText = try? await persistence.configurationText(for: id)
        try await persistence.saveConfigurationText(WgQuickConfigurationSerializer.serialize(configuration), for: id)
        records[index] = TunnelRecord(updatedTunnel)
        do {
            try await persistence.records.saveRecords(records)
        } catch {
            await persistence.restoreConfigurationText(previousText, for: id)
            throw error
        }
        return updatedTunnel
    }
}
