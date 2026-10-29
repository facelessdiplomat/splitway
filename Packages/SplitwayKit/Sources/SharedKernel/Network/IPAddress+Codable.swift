extension IPAddress: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let address = try? IPAddress(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid IP address: \(text)")
        }
        self = address
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
