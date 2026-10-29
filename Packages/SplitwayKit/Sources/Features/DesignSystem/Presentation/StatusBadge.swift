import SwiftUI

public struct StatusBadge: View {
    private static let horizontalPadding: CGFloat = 10
    private static let verticalPadding: CGFloat = 4
    private static let backgroundOpacity = 0.14

    private let title: Text
    private let tone: StatusTone

    public init(_ title: Text, tone: StatusTone) {
        self.title = title
        self.tone = tone
    }

    public var body: some View {
        Label {
            title
        } icon: {
            Image(systemName: tone.symbolName)
                .foregroundStyle(tone.color)
                .symbolEffect(.rotate, isActive: tone == .progress)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, Self.horizontalPadding)
        .padding(.vertical, Self.verticalPadding)
        .background(tone.color.opacity(Self.backgroundOpacity), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

#Preview("Status badges") {
    VStack(alignment: .leading) {
        ForEach(StatusTone.allCases, id: \.self) { tone in
            StatusBadge(Text(verbatim: "\(tone)"), tone: tone)
        }
    }
    .padding()
}
