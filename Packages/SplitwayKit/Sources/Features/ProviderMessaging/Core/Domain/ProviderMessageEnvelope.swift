struct ProviderMessageEnvelope<Payload: Codable>: Codable {
    let protocolVersion: Int
    let payload: Payload
}

struct ProviderMessageVersion: Decodable {
    let protocolVersion: Int
}
