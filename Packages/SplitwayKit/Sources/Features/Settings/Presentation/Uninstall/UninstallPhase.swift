import Settings

public enum UninstallPhase: Sendable, Equatable {
    case idle
    case confirming
    case removing
    case finished(UninstallReport)
}
