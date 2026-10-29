import SwiftUI

struct TunnelListToolbar: ToolbarContent {
    let addition: TunnelAdditionOptions
    let isReorderable: Bool

    var body: some ToolbarContent {
        #if os(iOS)
            if isReorderable {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        #endif
        if !addition.methods.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    TunnelAdditionButtons(addition: addition)
                } label: {
                    Label {
                        Text("Add tunnel", bundle: .module)
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}
