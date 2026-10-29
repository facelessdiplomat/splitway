public enum LogSource: String, Sendable, Hashable, Codable, CaseIterable {
    case application
    case tunnelExtension = "tunnel-extension"
    case engine
}
