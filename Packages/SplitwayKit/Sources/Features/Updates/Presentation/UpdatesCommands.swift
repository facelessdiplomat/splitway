import SwiftUI

public struct UpdatesCommands: Commands {
    private let model: UpdatesModel

    public init(model: UpdatesModel) {
        self.model = model
    }

    public var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button {
                Task.immediate { await model.checkForUpdates() }
            } label: {
                Text("Check for Updates…", bundle: .module)
            }
            .disabled(!model.canCheckForUpdates)
        }
    }
}
