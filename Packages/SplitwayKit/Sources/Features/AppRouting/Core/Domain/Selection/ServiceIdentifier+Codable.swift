extension ServiceIdentifier: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let identifier = try? ServiceIdentifier(text) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid service identifier: \(text)")
        }
        self = identifier
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(text)
    }
}
