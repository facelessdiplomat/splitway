import Foundation

enum SpikeLog {
    private static let groupIdentifier = "group.com.facelessdiplomat.splitway"
    private static let logPath = "Library/Logs/Splitway/sp8.log"

    static func record(_ message: String) {
        guard
            let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
        else { return }
        let file = container.appending(path: logPath)
        let directory = file.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let process = "\(ProcessInfo.processInfo.processName) \(Bundle.main.bundleIdentifier ?? "?")"
        let line = "\(Date().formatted(.iso8601)) \(process) \(message)\n"
        if let handle = try? FileHandle(forWritingTo: file) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? Data(line.utf8).write(to: file)
        }
    }
}
