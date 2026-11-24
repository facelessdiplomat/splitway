import SwiftUI

struct TunnelListToolbar: ToolbarContent {
    let addition: TunnelAdditionOptions
    let export: TunnelExportModel
    let hasTunnels: Bool
    let navigation: TunnelLibraryNavigation

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
                navigation.showLog()
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
        if let showSettings = navigation.showSettings {
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showSettings()
                } label: {
                    Label {
                        Text("Settings", bundle: .module)
                    } icon: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}
