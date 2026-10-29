public struct ApplicationSelection: Sendable, Hashable {
    public let applications: [ApplicationIdentity]

    public init(_ applications: [ApplicationIdentity]) {
        var seenPaths: Set<String> = []
        self.applications = applications.filter { application in seenPaths.insert(application.path).inserted }
    }

    public var isEmpty: Bool {
        applications.isEmpty
    }
}
