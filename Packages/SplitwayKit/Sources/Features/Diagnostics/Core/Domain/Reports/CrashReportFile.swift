import Foundation

public struct CrashReportFile: Sendable, Hashable {
    public let name: String
    public let contents: Data

    public init(name: String, contents: Data) {
        self.name = name
        self.contents = contents
    }
}
