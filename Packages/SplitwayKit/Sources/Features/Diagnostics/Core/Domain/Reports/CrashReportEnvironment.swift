public struct CrashReportEnvironment: Sendable, Hashable {
    public let application: String
    public let system: String

    public init(application: String, system: String) {
        self.application = application
        self.system = system
    }
}
