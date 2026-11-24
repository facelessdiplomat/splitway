import SwiftUI

struct CrashReportPresenter: ViewModifier {
    private static let minimumWidth: CGFloat = 480
    private static let minimumHeight: CGFloat = 420

    @Bindable var model: LogViewerModel

    func body(content: Content) -> some View {
        content.sheet(item: $model.crashReport) { report in
            NavigationStack {
                CrashReportView(model: report) {
                    model.crashReport = nil
                }
            }
            #if os(macOS)
                .frame(minWidth: Self.minimumWidth, minHeight: Self.minimumHeight)
            #endif
        }
    }
}
