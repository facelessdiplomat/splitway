public struct CrashReportBundle: Sendable, Hashable {
    public let files: [CrashReportFile]
    public let includedLogEntryCount: Int
    public let includedReportCount: Int
    public let isTruncated: Bool

    public init(files: [CrashReportFile], includedLogEntryCount: Int, includedReportCount: Int, isTruncated: Bool) {
        self.files = files
        self.includedLogEntryCount = includedLogEntryCount
        self.includedReportCount = includedReportCount
        self.isTruncated = isTruncated
    }

    public var isEmpty: Bool {
        includedLogEntryCount == 0 && includedReportCount == 0
    }

    public var byteCount: Int {
        files.reduce(0) { total, file in total + file.contents.count }
    }
}
