import Settings

public struct RecordingUninstallAction: UninstallAction {
    public let step: UninstallStep
    private let recorder: UninstallStepRecorder
    private let fails: Bool

    public init(_ step: UninstallStep, recorder: UninstallStepRecorder, fails: Bool = false) {
        self.step = step
        self.recorder = recorder
        self.fails = fails
    }

    public func perform() async throws(UninstallStepFailure) {
        recorder.record(step)
        if fails {
            throw UninstallStepFailure()
        }
    }
}
