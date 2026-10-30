import Synchronization
import TransparentProxy

public final class RecordingSuspiciousAttributionLog: SuspiciousAttributionLog {
    private let paths = Mutex<[String]>([])

    public init() {}

    public var networkExtensionPaths: [String] {
        paths.withLock { paths in paths }
    }

    public func recordFlow(attributedToNetworkExtensionAt executablePath: String) {
        paths.withLock { paths in paths.append(executablePath) }
    }
}
