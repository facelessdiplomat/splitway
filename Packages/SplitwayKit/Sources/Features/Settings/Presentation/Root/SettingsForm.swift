import DesignSystemPresentation
import Settings
import SwiftUI

struct SettingsForm: View {
    let version: AppVersion
    let notices: ThirdPartyNoticesModel

    var body: some View {
        Form {
            Section {
                KeyValueRow(Text("Version", bundle: .module), value: Text(verbatim: version.marketingVersion))
                KeyValueRow(Text("Build", bundle: .module), value: Text(verbatim: version.build))
            } header: {
                Text("About", bundle: .module)
            }
            Section {
                NavigationLink {
                    ThirdPartyNoticeListView(model: notices)
                } label: {
                    Text("Open Source Licenses", bundle: .module)
                }
            }
        }
        .formStyle(.grouped)
    }
}
