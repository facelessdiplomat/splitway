import SharedKernel

extension RoutingPolicySnapshot: Codable {
    private static let currentSchemaVersion = 1

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case applications
        case tunnelNetworks
        case whenTunnelUnavailable
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        guard schemaVersion == Self.currentSchemaVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported routing snapshot schema version \(schemaVersion)"
            )
        }
        self.init(
            applications: try container.decode([ApplicationIdentity].self, forKey: .applications),
            tunnelNetworks: IPNetworkSet(try container.decode([IPNetwork].self, forKey: .tunnelNetworks)),
            whenTunnelUnavailable: try container.decode(TunnelUnavailableBehavior.self, forKey: .whenTunnelUnavailable)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentSchemaVersion, forKey: .schemaVersion)
        try container.encode(applications, forKey: .applications)
        try container.encode(tunnelNetworks.networks, forKey: .tunnelNetworks)
        try container.encode(whenTunnelUnavailable, forKey: .whenTunnelUnavailable)
    }
}
