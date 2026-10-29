import AppRouting

public struct InstalledApplication: Sendable, Hashable, Identifiable {
    public let kind: ApplicationKind
    public let name: String
    public let bundleIdentifier: String?
    public let path: String
    public let version: String?

    public init(kind: ApplicationKind, name: String, bundleIdentifier: String?, path: String, version: String?) {
        self.kind = kind
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.version = version
    }

    public var id: String {
        path
    }
}
