import DesignSystemPresentation
import Settings
import SwiftUI

struct SettingsForm: View {
    let version: AppVersion
    let notices: ThirdPartyNoticesModel
    let loginItem: LoginItemModel?
    let uninstall: UninstallModel?

    var body: some View {
        Form {
            if let loginItem {
                LoginItemSection(model: loginItem)
            }
            Section {
                KeyValueRow(Text("Version", bundle: .module), value: Text(verbatim: version.marketingVersion))
                KeyValueRow(Text("Build", bundle: .module), value: Text(verbatim: version.build))
            } header: {
                Text("About", bundle: .module)
                    .foregroundStyle(.supportingText)
            }
            Section {
                NavigationLink {
                    ThirdPartyNoticeListView(model: notices)
                } label: {
                    Text("Open Source Licenses", bundle: .module)
                }
            }
            if let uninstall {
                UninstallSection(model: uninstall)
            }
        }
        .formStyle(.grouped)
    }
}
