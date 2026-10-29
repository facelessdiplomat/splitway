import Observation
import SystemExtension

@MainActor
@Observable
public final class SystemExtensionWizardModel {
    public private(set) var step = SystemExtensionWizardStep.introduction
    private var isPostponed = false
    private var isActivating = false

    private let activate: EnsureSystemExtensionActivatedUseCase

    public init(activate: EnsureSystemExtensionActivatedUseCase) {
        self.activate = activate
    }

    public var needsAttention: Bool {
        step.needsAttention && !isPostponed
    }

    public func install() async {
        guard !isActivating else { return }
        isActivating = true
        isPostponed = false
        defer { isActivating = false }
        for await state in activate.execute() {
            step = SystemExtensionWizardStep(state: state)
        }
    }

    public func postpone() {
        isPostponed = true
    }
}
