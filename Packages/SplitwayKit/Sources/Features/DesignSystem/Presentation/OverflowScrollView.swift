import SwiftUI

public struct OverflowScrollView<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
        }
    }
}

#Preview("Overflow scroll view") {
    OverflowScrollView {
        Text(verbatim: "Scrolls only when the content does not fit.")
            .padding()
    }
}
