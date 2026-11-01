import SwiftUI
import WidgetKit

@main
struct SplitwayControls: WidgetBundle {
    init() {
        ControlsComposition(configuration: AppConfiguration(bundle: .main)).registerDependencies()
    }

    var body: some Widget {
        TunnelControl()
    }
}
