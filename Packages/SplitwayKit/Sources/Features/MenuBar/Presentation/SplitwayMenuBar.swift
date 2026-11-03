import SwiftUI

public struct SplitwayMenuBar: Scene {
    private let model: MenuBarModel
    private let mainWindowIdentifier: String

    public init(model: MenuBarModel, mainWindowIdentifier: String) {
        self.model = model
        self.mainWindowIdentifier = mainWindowIdentifier
    }

    public var body: some Scene {
        MenuBarExtra {
            MenuBarMenu(model: model)
        } label: {
            MenuBarLabel(model: model, mainWindowIdentifier: mainWindowIdentifier)
        }
    }
}
