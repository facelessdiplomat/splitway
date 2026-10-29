import Diagnostics
import SwiftUI

struct LogViewerFilterMenu: View {
    let model: LogViewerModel

    var body: some View {
        Menu {
            Picker(selection: minimumLevel) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    level.title.tag(level)
                }
            } label: {
                Text("Minimum level", bundle: .module)
            }
            .pickerStyle(.menu)
            Picker(selection: source) {
                Text("All sources", bundle: .module).tag(LogSource?.none)
                ForEach(LogSource.allCases, id: \.self) { source in
                    source.title.tag(LogSource?.some(source))
                }
            } label: {
                Text("Source", bundle: .module)
            }
            .pickerStyle(.menu)
        } label: {
            Label {
                Text("Filter", bundle: .module)
            } icon: {
                Image(systemName: symbolName)
            }
        }
    }

    private var symbolName: String {
        model.filter.restrictsLevelOrSource
            ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
    }

    private var minimumLevel: Binding<LogLevel> {
        Binding {
            model.filter.minimumLevel
        } set: { level in
            model.setMinimumLevel(level)
        }
    }

    private var source: Binding<LogSource?> {
        Binding {
            model.filter.source
        } set: { source in
            model.setSource(source)
        }
    }
}
