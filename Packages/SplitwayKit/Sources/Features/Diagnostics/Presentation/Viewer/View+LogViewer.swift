import SwiftUI

extension View {
    public func logViewer(_ presenter: LogViewerPresenter) -> some View {
        modifier(LogViewerSheet(presenter: presenter))
    }
}
