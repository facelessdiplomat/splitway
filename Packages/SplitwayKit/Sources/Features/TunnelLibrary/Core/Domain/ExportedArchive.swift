import Foundation

public struct ExportedArchive: Sendable, Hashable {
    public let contents: Data
    public let skippedTunnels: [TunnelName]
}
