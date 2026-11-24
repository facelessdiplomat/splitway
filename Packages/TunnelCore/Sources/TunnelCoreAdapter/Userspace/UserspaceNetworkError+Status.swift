#if os(macOS)
    import TunnelCoreFramework
    import TunnelEngine

    extension UserspaceNetworkError {
        private static let errorsByStatus: [TCStatus: UserspaceNetworkError] = [
            .connectionFailed: .connectionFailed,
            .timedOut: .timedOut,
            .lookupFailed: .lookupFailed,
            .networkStopped: .networkStopped,
            .connectionClosed: .connectionClosed,
        ]

        init?(status: TCStatus, releasedHandle: UserspaceNetworkError) {
            switch status {
            case .OK: return nil
            case .unknownHandle: self = releasedHandle
            default: self = Self.errorsByStatus[status] ?? .internalFailure
            }
        }

        init?(finishing status: TCStatus) {
            guard status != .OK else { return nil }
            self = .connectionFailed
        }

        static func check(
            _ status: TCStatus,
            whenHandleIsReleased releasedHandle: UserspaceNetworkError
        ) throws(UserspaceNetworkError) {
            if let error = UserspaceNetworkError(status: status, releasedHandle: releasedHandle) {
                throw error
            }
        }
    }
#endif
