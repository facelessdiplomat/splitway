public struct ThirdPartyNotice: Sendable, Equatable, Identifiable {
    public let name: String
    public let licenseName: String
    public let dependencies: [String]
    public let text: String

    public var id: String {
        name
    }

    public init(name: String, licenseName: String, dependencies: [String], text: String) {
        self.name = name
        self.licenseName = licenseName
        self.dependencies = dependencies
        self.text = text
    }
}
