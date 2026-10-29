extension DomainName: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let name = try? DomainName(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid domain name: \(text)")
        }
        self = name
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
