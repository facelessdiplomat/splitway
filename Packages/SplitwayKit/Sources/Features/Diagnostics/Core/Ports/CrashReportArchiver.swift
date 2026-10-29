import Foundation

public protocol CrashReportArchiver: Sendable {
    func archive(_ bundle: CrashReportBundle) throws(CrashReportArchivingError) -> Data
}
