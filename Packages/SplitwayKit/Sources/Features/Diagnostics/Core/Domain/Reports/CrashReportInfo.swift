import Foundation

public struct CrashReportInfo: Sendable, Hashable {
    public let application: String
    public let system: String
    public let createdAt: Date

    public init(application: String, system: String, createdAt: Date) {
        self.application = application
        self.system = system
        self.createdAt = createdAt
    }

    var text: String {
        "\(application)\n\(system)\nCreated \(createdAt.formatted(.iso8601))\n"
    }
}
