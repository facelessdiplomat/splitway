import Observation
import Settings

@MainActor
@Observable
public final class UninstallModel {
    public private(set) var phase: UninstallPhase = .idle
    public private(set) var trashFailure: ApplicationRemovalError?

    private let uninstall: UninstallUseCase
    private let application: any ApplicationRemoval

    public init(uninstall: UninstallUseCase, application: any ApplicationRemoval) {
        self.uninstall = uninstall
        self.application = application
    }

    public func requestUninstall() {
        guard phase == .idle else { return }
        phase = .confirming
    }

    public func cancel() {
        guard phase == .confirming else { return }
        phase = .idle
    }

    public func confirm() async {
        guard phase == .confirming else { return }
        phase = .removing
        phase = .finished(await uninstall.execute())
    }

    public func moveToTrash() async {
        do {
            try await application.moveToTrashAndQuit()
        } catch {
            trashFailure = error
        }
    }

    public func quit() async {
        await application.quit()
    }

    public func dismissTrashFailure() {
        trashFailure = nil
    }
}
