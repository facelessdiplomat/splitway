import TunnelCoreFramework
import TunnelEngine

extension TunnelEngineError {
    init?(status: TCStatus) {
        switch status {
        case .OK: return nil
        case .invalidArgument, .internalFailure, .connectionFailed, .timedOut, .lookupFailed, .connectionClosed:
            self = .internalFailure
        case .unknownHandle, .networkStopped: self = .deviceNotRunning
        case .tunnelInterfaceUnavailable: self = .tunnelInterfaceUnavailable
        case .configurationRejected: self = .configurationRejected
        case .deviceUnavailable: self = .socketsUnavailable
        }
    }

    static func check(_ status: TCStatus) throws(TunnelEngineError) {
        if let error = TunnelEngineError(status: status) {
            throw error
        }
    }
}
