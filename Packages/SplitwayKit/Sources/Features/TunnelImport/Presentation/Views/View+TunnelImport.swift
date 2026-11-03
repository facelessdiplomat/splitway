import SwiftUI

extension View {
    public func tunnelImport(_ model: TunnelImportModel) -> some View {
        modifier(TunnelImportPresenter(model: model))
    }
}
