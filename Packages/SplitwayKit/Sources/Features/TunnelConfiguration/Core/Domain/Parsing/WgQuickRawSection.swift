public struct WgQuickRawEntry: Sendable, Equatable {
    public let key: String
    public let value: String
    public let line: Int
}

public struct WgQuickRawSection: Sendable, Equatable {
    public let section: WgQuickSection
    public let headerLine: Int
    public internal(set) var entries: [WgQuickRawEntry]
}
