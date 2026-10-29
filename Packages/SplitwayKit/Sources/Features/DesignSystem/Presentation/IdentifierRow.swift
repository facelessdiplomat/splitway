import SwiftUI

public struct IdentifierRow: View {
    private static let minimumScaleFactor = 0.5

    private let title: Text
    private let identifier: String

    public init(_ title: Text, identifier: String) {
        self.title = title
        self.identifier = identifier
    }

    public var body: some View {
        VStack(alignment: .leading) {
            title
            Text(verbatim: identifier)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(Self.minimumScaleFactor)
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
