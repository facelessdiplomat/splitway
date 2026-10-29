struct ConnectionStateMachine {
    private(set) var state: ConnectionState = .disconnected

    func needsDisconnectReason(for status: SystemConnectionStatus) -> Bool {
        status.endsSession && state.isSessionInProgress
    }

    mutating func apply(_ status: SystemConnectionStatus, disconnectReason: ConnectionFailure?) -> ConnectionState {
        switch status {
        case .connecting:
            state = .connecting
        case .connected(let since):
            state = .connected(since: since)
        case .reasserting:
            state = .reasserting
        case .disconnecting:
            state = .disconnecting
        case .notConfigured, .disconnected:
            if let disconnectReason {
                state = .failed(disconnectReason)
            } else if !state.isFailure {
                state = .disconnected
            }
        }
        return state
    }
}
