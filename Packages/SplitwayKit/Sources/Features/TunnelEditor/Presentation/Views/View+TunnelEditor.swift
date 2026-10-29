import SwiftUI

extension View {
    public func tunnelEditor(_ flow: TunnelEditorFlow) -> some View {
        modifier(TunnelEditorPresenter(flow: flow))
    }
}
