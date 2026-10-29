import AppRouting
import TunnelConfiguration

public struct CreateTunnelUseCase: Sendable {
    private let persistence: TunnelPersistence

    public init(records: any TunnelRecordRepository, secrets: any TunnelSecretStore) {
        persistence = TunnelPersistence(records: records, secrets: secrets)
    }

    public func execute(
        name: TunnelName,
        configuration: TunnelConfiguration,
        routingPolicy: RoutingPolicy = .default
    ) async throws(TunnelLibraryError) -> Tunnel {
        let existingRecords = try await persistence.records.loadRecords()
        let tunnel = Tunnel(
            name: UniqueTunnelNameResolver.uniqueName(for: name, takenNames: existingRecords.map(\.name)),
            configuration: configuration,
            routingPolicy: routingPolicy
        )
        try await persistence.add(tunnel, after: existingRecords)
        return tunnel
    }
}
