extension IPNetwork: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let network = try? IPNetwork(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid IP network: \(text)")
        }
        self = network
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
