import SwiftUI

struct RoutingSelectionSummary: View {
    let model: RoutingSectionModel

    var body: some View {
        switch model.selectedMode {
        case .allTraffic:
            EmptyView()
        case .selectedApplications:
            Text("\(model.selectedApplicationCount) apps selected", bundle: .module)
                .foregroundStyle(.secondary)
        case .selectedServices:
            Text("\(model.selectedServiceCount) services selected", bundle: .module)
                .foregroundStyle(.secondary)
        }
        ForEach(model.warnings, id: \.self) { warning in
            Label {
                warning.message
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .font(.subheadline)
        }
    }
}
