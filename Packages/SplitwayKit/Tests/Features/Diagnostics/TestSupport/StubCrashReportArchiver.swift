import Diagnostics
import Foundation

public struct StubCrashReportArchiver: CrashReportArchiver {
    private let fails: Bool

    public init(fails: Bool = false) {
        self.fails = fails
    }

    public func archive(_ bundle: CrashReportBundle) throws(CrashReportArchivingError) -> Data {
        guard !fails else { throw .failed }
        return Data(bundle.files.map(\.name).joined(separator: " ").utf8)
    }
}
