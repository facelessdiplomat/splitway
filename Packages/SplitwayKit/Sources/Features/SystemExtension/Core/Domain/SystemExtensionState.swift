public enum SystemExtensionState: Sendable, Hashable {
    case activating
    case awaitingUserApproval
    case activated
    case requiresReboot
    case failed(SystemExtensionFailure)

    init(after event: SystemExtensionActivationEvent) {
        switch event {
        case .needsUserApproval: self = .awaitingUserApproval
        case .completed: self = .activated
        case .willCompleteAfterReboot: self = .requiresReboot
        case .failed(let failure): self = .failed(failure)
        }
    }
}
