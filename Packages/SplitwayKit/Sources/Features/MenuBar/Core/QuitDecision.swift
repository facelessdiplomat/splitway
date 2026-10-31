public enum QuitDecision: Sendable, Hashable {
    case disconnectAndQuit
    case quitKeepingConnection
    case stay
}
