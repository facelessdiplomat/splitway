import SystemExtension

public enum SystemExtensionWizardStep: Sendable, Hashable {
    case introduction
    case installing
    case awaitingApproval
    case ready
    case restartRequired
    case failed(SystemExtensionFailure)

    public init(state: SystemExtensionState) {
        switch state {
        case .activating: self = .installing
        case .awaitingUserApproval: self = .awaitingApproval
        case .activated: self = .ready
        case .requiresReboot: self = .restartRequired
        case .failed(let failure): self = .failed(failure)
        }
    }

    public var needsAttention: Bool {
        switch self {
        case .awaitingApproval, .restartRequired, .failed: true
        case .introduction, .installing, .ready: false
        }
    }
}
