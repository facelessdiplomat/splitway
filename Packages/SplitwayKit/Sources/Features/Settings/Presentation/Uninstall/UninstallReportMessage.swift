import Settings
import SwiftUI

struct UninstallReportMessage: View {
    let report: UninstallReport

    var body: some View {
        if report.isComplete {
            Text("Move Splitway to the Trash to finish.", bundle: .module)
        } else {
            let parts = report.failedSteps.map(\.title).formatted(.list(type: .and))
            Text("These parts weren’t removed: \(parts). Move Splitway to the Trash to finish.", bundle: .module)
        }
    }
}
