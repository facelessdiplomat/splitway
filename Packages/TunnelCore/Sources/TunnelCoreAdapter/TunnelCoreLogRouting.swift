import Diagnostics
import Synchronization
import TunnelCoreFramework

public enum TunnelCoreLogRouting {
    private static let retainedDestinations = Mutex<[EngineLogDestination]>([])

    public static func route(to recorder: LogRecorder) {
        let destination = EngineLogDestination(recorder: recorder)
        retainedDestinations.withLock { destinations in
            destinations.append(destination)
            tc_set_log_callback(forwardEngineLog, Unmanaged.passUnretained(destination).toOpaque())
        }
    }
}

final class EngineLogDestination: Sendable {
    let recorder: LogRecorder

    init(recorder: LogRecorder) {
        self.recorder = recorder
    }

    func forward(level: TCLogLevel, message: String) {
        recorder.record(level == .error ? .error : .debug, message)
    }
}

private func forwardEngineLog(context: UnsafeMutableRawPointer?, level: TCLogLevel, message: UnsafePointer<CChar>) {
    guard let context else { return }
    let destination = Unmanaged<EngineLogDestination>.fromOpaque(context).takeUnretainedValue()
    destination.forward(level: level, message: String(cString: message))
}
