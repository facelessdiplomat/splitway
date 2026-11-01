import SwiftUI

struct TunnelAdditionButtons: View {
    let addition: TunnelAdditionOptions

    var body: some View {
        ForEach(addition.methods, id: \.self) { method in
            if method.usesSystemPasteButton {
                PasteButton(payloadType: String.self) { texts in
                    addition.paste(texts)
                }
                .buttonBorderShape(.capsule)
            } else {
                Button {
                    addition.add(method)
                } label: {
                    method.label
                }
            }
        }
    }
}
