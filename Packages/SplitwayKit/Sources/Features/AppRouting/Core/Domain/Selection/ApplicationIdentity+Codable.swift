extension ApplicationIdentity: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case displayName
        case path
        case signingIdentifiers
        case teamIdentifier
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            try self.init(
                kind: container.decode(ApplicationKind.self, forKey: .kind),
                displayName: container.decode(String.self, forKey: .displayName),
                path: container.decode(String.self, forKey: .path),
                signingIdentifiers: container.decodeIfPresent([String].self, forKey: .signingIdentifiers) ?? [],
                teamIdentifier: container.decodeIfPresent(String.self, forKey: .teamIdentifier)
            )
        } catch let error as ApplicationIdentityError {
            throw DecodingError.dataCorruptedError(
                forKey: .path,
                in: container,
                debugDescription: "Invalid application identity: \(error)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(path, forKey: .path)
        try container.encode(signingIdentifiers, forKey: .signingIdentifiers)
        try container.encodeIfPresent(teamIdentifier, forKey: .teamIdentifier)
    }
}
