import DesignSystemPresentation
import SwiftUI

public struct UpdatesSection: View {
    private let model: UpdatesModel

    public init(model: UpdatesModel) {
        self.model = model
    }

    public var body: some View {
        Section {
            Toggle(isOn: checksAutomatically) {
                Text("Check for Updates Automatically", bundle: .module)
            }
            Button {
                Task.immediate { await model.checkForUpdates() }
            } label: {
                Text("Check for Updates Now", bundle: .module)
            }
            .disabled(!model.canCheckForUpdates)
            Text(
                "Splitway asks GitHub for new versions. GitHub sees your IP address and the app version.",
                bundle: .module
            )
            .font(.footnote)
            .foregroundStyle(.supportingText)
        } header: {
            Text("Updates", bundle: .module)
                .foregroundStyle(.supportingText)
        }
        .task { await model.load() }
    }

    private var checksAutomatically: Binding<Bool> {
        Binding {
            model.checksAutomatically
        } set: { checksAutomatically in
            Task.immediate { await model.setChecksAutomatically(checksAutomatically) }
        }
    }
}
