import SwiftUI

extension EmptyStateView where Actions == EmptyView {
    public init(_ title: Text, systemImage: String, message: Text) {
        self.init(title, systemImage: systemImage, message: message) {
            EmptyView()
        }
    }
}
