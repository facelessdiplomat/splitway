import AppRouting
import Synchronization

public final class SuspiciousAttributionMonitor: Sendable {
    private static let systemExtensionsDirectory = "/Library/SystemExtensions/"

    private let log: any SuspiciousAttributionLog
    private let reportedPaths = Mutex<Set<String>>([])

    public init(log: any SuspiciousAttributionLog) {
        self.log = log
    }

    public func inspect(_ source: SourceApplication) {
        guard let executablePath = source.executablePath,
            executablePath.hasPrefix(Self.systemExtensionsDirectory)
        else { return }
        let isFirstFlow = reportedPaths.withLock { paths in paths.insert(executablePath).inserted }
        if isFirstFlow {
            log.recordFlow(attributedToNetworkExtensionAt: executablePath)
        }
    }
}
