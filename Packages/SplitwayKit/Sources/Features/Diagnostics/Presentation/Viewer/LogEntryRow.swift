import Diagnostics
import SwiftUI

struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label {
                    entry.level.title
                } icon: {
                    Image(systemName: entry.level.symbolName)
                        .foregroundStyle(entry.level.color)
                }
                entry.source.title
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.date, format: .dateTime.hour().minute().second())
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.caption)
            Text(verbatim: entry.message)
                .font(.caption.monospaced())
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
    }
}
