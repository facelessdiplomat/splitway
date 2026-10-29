import SwiftUI

public struct KeyValueRow: View {
    private let key: Text
    private let value: Text
    private let usesMonospacedValue: Bool

    public init(_ key: Text, value: Text, usesMonospacedValue: Bool = false) {
        self.key = key
        self.value = value
        self.usesMonospacedValue = usesMonospacedValue
    }

    public var body: some View {
        LabeledContent {
            value
                .font(usesMonospacedValue ? .body.monospaced() : .body)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        } label: {
            key
        }
    }
}

#Preview("Key value rows") {
    Form {
        KeyValueRow(Text(verbatim: "Endpoint"), value: Text(verbatim: "vpn.example.com:51820"))
        KeyValueRow(
            Text(verbatim: "Public key"),
            value: Text(verbatim: "hSDwCYkwp1R0i33ctD73Wg2/Og0mOBr066SpjqqbTmo="),
            usesMonospacedValue: true
        )
    }
}
