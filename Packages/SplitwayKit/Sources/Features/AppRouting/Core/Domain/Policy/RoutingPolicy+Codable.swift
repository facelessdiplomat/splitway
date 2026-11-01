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
            modeKind: modeKind,
            applicationSelection: ApplicationSelection(
                try Self.decodeSelection(.applications, isRequired: modeKind == .selectedApplications, from: container)
            ),
            serviceSelection: ServiceSelection(
                try Self.decodeSelection(.services, isRequired: modeKind == .selectedServices, from: container)
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
        if mode.kind == .selectedServices || !serviceSelection.isEmpty {
            try container.encode(serviceSelection.services, forKey: .services)
        }
    }

    private static func decodeSelection<Element: Decodable>(
        _ key: CodingKeys,
        isRequired: Bool,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> [Element] {
        guard isRequired else {
            return try container.decodeIfPresent([Element].self, forKey: key) ?? []
        }
        return try container.decode([Element].self, forKey: key)
    }
}
