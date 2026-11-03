extension RoutingPolicy: Codable {
    private static let currentSchemaVersion = 1
    private static let retiredServicesMode = "selectedServices"

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case mode
        case applications
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
        let modeKind = try Self.decodeModeKind(from: container)
        self.init(
            modeKind: modeKind,
            applicationSelection: ApplicationSelection(
                try Self.decodeApplications(isRequired: modeKind == .selectedApplications, from: container)
            ),
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
        if mode.kind == .selectedApplications || !applicationSelection.isEmpty {
            try container.encode(applicationSelection.applications, forKey: .applications)
        }
    }

    private static func decodeModeKind(from container: KeyedDecodingContainer<CodingKeys>) throws -> RoutingModeKind {
        let name = try container.decode(String.self, forKey: .mode)
        if name == retiredServicesMode {
            return .allTraffic
        }
        guard let kind = RoutingModeKind(rawValue: name) else {
            throw DecodingError.dataCorruptedError(
                forKey: .mode,
                in: container,
                debugDescription: "Unknown routing mode \(name)"
            )
        }
        return kind
    }

    private static func decodeApplications(
        isRequired: Bool,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> [ApplicationIdentity] {
        guard isRequired else {
            return try container.decodeIfPresent([ApplicationIdentity].self, forKey: .applications) ?? []
        }
        return try container.decode([ApplicationIdentity].self, forKey: .applications)
    }
}
