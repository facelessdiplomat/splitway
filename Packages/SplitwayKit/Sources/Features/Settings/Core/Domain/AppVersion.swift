public struct AppVersion: Sendable, Equatable {
    public let marketingVersion: String
    public let build: String

    public init(marketingVersion: String, build: String) {
        self.marketingVersion = marketingVersion
        self.build = build
    }
}
