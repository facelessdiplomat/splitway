import SwiftUI

extension View {
    public func settingsSheet(_ presenter: SettingsPresenter) -> some View {
        modifier(SettingsSheet(presenter: presenter))
    }
}
