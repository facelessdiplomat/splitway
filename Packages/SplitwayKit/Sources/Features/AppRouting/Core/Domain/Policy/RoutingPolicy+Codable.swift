extension RoutingPolicy: Codable {
    private static let currentSchemaVersion = 1

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case mode
        case applications
        case services
        case whenTunnelUnavailable
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        guard schemaVersion == Self.currentSchemaVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported routing policy schema version \(schemaVersion)"
            )
        }
        let modeKind = try container.decode(RoutingModeKind.self, forKey: .mode)
        self.init(
            mode: try Self.decodeMode(of: modeKind, from: container),
            whenTunnelUnavailable: try container.decodeIfPresent(
                TunnelUnavailableBehavior.self,
                forKey: .whenTunnelUnavailable
            ) ?? .block
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentSchemaVersion, forKey: .schemaVersion)
        try container.encode(mode.kind, forKey: .mode)
        try container.encode(whenTunnelUnavailable, forKey: .whenTunnelUnavailable)
        switch mode {
        case .allTraffic:
            break
        case .selectedApplications(let selection):
            try container.encode(selection.applications, forKey: .applications)
        case .selectedServices(let selection):
            try container.encode(selection.services, forKey: .services)
        }
    }

    private static func decodeMode(
        of kind: RoutingModeKind,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> RoutingMode {
        switch kind {
        case .allTraffic:
            return .allTraffic
        case .selectedApplications:
            return .selectedApplications(
                ApplicationSelection(try container.decode([ApplicationIdentity].self, forKey: .applications))
            )
        case .selectedServices:
            return .selectedServices(
                ServiceSelection(try container.decode([ServiceIdentifier].self, forKey: .services)))
        }
    }
}
