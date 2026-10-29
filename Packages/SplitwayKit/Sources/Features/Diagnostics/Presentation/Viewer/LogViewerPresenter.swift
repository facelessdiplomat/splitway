import Observation

@MainActor
@Observable
public final class LogViewerPresenter {
    public var isShowing = false
    let model: LogViewerModel

    public init(model: LogViewerModel) {
        self.model = model
    }

    public func show() {
        isShowing = true
    }
}
