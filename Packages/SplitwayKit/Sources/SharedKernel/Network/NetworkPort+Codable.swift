extension NetworkPort: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let number = try container.decode(Int.self)
        guard let port = try? NetworkPort(number) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid network port: \(number)")
        }
        self = port
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
