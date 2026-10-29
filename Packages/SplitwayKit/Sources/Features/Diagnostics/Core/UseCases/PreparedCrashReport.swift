import Foundation

public struct PreparedCrashReport: Sendable, Equatable {
    public let bundle: CrashReportBundle
    public let archive: Data

    public init(bundle: CrashReportBundle, archive: Data) {
        self.bundle = bundle
        self.archive = archive
    }
}
