import TunnelLibrary

struct TunnelRecordsDocument: Codable {
    let schemaVersion: Int
    let tunnels: [TunnelRecord]
}
