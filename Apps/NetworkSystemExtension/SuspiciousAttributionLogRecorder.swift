import Diagnostics
import TransparentProxy

struct SuspiciousAttributionLogRecorder: SuspiciousAttributionLog {
    let log: LogRecorder

    func recordFlow(attributedToNetworkExtensionAt executablePath: String) {
        log.record(
            .warning,
            "A flow came from the network extension at \(executablePath): another proxy or VPN may hide its source app"
        )
    }
}
