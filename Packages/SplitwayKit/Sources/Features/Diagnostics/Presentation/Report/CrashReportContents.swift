import DesignSystemPresentation
import Diagnostics
import SwiftUI

struct CrashReportContents: View {
    let report: PreparedCrashReport

    var body: some View {
        Form {
            Section {
                Text(
                    "Splitway never sends reports by itself. Keys are removed from the log and the crash reports.",
                    bundle: .module
                )
                if report.bundle.isEmpty {
                    Text("No log entries or crash reports have been recorded yet.", bundle: .module)
                        .foregroundStyle(.supportingText)
                }
                if report.bundle.isTruncated {
                    Text("The oldest entries were left out to keep the archive small.", bundle: .module)
                        .foregroundStyle(.supportingText)
                }
            }
            Section {
                ForEach(report.bundle.files, id: \.name) { file in
                    KeyValueRow(
                        Text(verbatim: file.name),
                        value: Text(Int64(file.contents.count), format: .byteCount(style: .file))
                    )
                }
            } header: {
                Text("Archive contents", bundle: .module)
                    .foregroundStyle(.supportingText)
            }
            Section {
                ShareLink(item: archive, preview: SharePreview(Text("Splitway Report", bundle: .module))) {
                    Label {
                        Text("Share Report", bundle: .module)
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var archive: CrashReportArchive {
        CrashReportArchive(
            data: report.archive, fileName: String(localized: "Splitway Report", bundle: .module) + ".zip")
    }
}
