import Settings
import SwiftUI

struct ThirdPartyNoticeView: View {
    private static let paragraphSpacing: CGFloat = 12

    let notice: ThirdPartyNotice

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Self.paragraphSpacing) {
                ForEach(Array(notice.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(verbatim: paragraph)
                }
            }
            .font(.footnote)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(Text(verbatim: notice.name))
    }
}
