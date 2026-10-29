import SwiftUI

struct TunnelAdditionButtons: View {
    let addition: TunnelAdditionOptions

    var body: some View {
        ForEach(addition.methods, id: \.self) { method in
            Button {
                addition.add(method)
            } label: {
                method.label
            }
        }
    }
}
