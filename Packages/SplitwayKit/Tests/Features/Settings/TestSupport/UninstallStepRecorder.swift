import Settings
import Synchronization

public final class UninstallStepRecorder: Sendable {
    private let performed = Mutex<[UninstallStep]>([])

    public init() {}

    public var steps: [UninstallStep] {
        performed.withLock { steps in steps }
    }

    func record(_ step: UninstallStep) {
        performed.withLock { steps in steps.append(step) }
    }
}
