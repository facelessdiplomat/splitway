import DesignSystemPresentation
import Settings
import SwiftUI

struct ThirdPartyNoticeListView: View {
    let model: ThirdPartyNoticesModel

    var body: some View {
        content
            .navigationTitle(Text("Open Source Licenses", bundle: .module))
            .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView()
        case .loaded(let notices):
            List(notices) { notice in
                NavigationLink {
                    ThirdPartyNoticeView(notice: notice)
                } label: {
                    KeyValueRow(Text(verbatim: notice.name), value: Text(verbatim: notice.licenseName))
                }
            }
        case .unavailable:
            EmptyStateView(
                Text("Licenses are unavailable", bundle: .module),
                systemImage: "doc.questionmark",
                message: Text("The license texts couldn’t be read.", bundle: .module)
            )
        }
    }
}
