import SwiftUI

public struct IdentifierRow: View {
    private static let minimumScaleFactor = 0.5

    private let title: Text
    private let identifier: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(_ title: Text, identifier: String) {
        self.title = title
        self.identifier = identifier
    }

    public var body: some View {
        VStack(alignment: .leading) {
            title
            Text(verbatim: identifier)
                .font(.footnote.monospaced())
                .foregroundStyle(.supportingText)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : Self.minimumScaleFactor)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Identifier row") {
    Form {
        IdentifierRow(Text(verbatim: "Public key"), identifier: "hSDwCYkwp1R0i33ctD73Wg2/Og0mOBr066SpjqqbTmo=")
    }
}
