public enum SystemExtensionActivationEvent: Sendable, Hashable {
    case needsUserApproval
    case completed
    case willCompleteAfterReboot
    case failed(SystemExtensionFailure)
}
