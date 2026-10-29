import SwiftUI

struct TunnelListToolbar: ToolbarContent {
    let addition: TunnelAdditionOptions
    let export: TunnelExportModel
    let hasTunnels: Bool
    let showLog: @MainActor () -> Void

    var body: some ToolbarContent {
        #if os(iOS)
            if hasTunnels {
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
        ToolbarItem(placement: .secondaryAction) {
            Button {
                showLog()
            } label: {
                Label {
                    Text("Log", bundle: .module)
                } icon: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
            }
        }
        if hasTunnels {
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    export.requestExportOfAllTunnels()
                } label: {
                    Label {
                        Text("Export All Tunnels", bundle: .module)
                    } icon: {
                        Image(systemName: "square.and.arrow.up.on.square")
                    }
                }
            }
        }
    }
}
