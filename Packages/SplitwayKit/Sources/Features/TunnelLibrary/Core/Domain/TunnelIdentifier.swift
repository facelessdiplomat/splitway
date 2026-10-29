import Foundation

public struct TunnelIdentifier: Sendable, Hashable {
    public let rawValue: UUID

    public init() {
        rawValue = UUID()
    }

    public init(_ rawValue: UUID) {
        self.rawValue = rawValue
    }
}
