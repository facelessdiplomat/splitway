import Diagnostics
import SwiftUI

extension LogLevel {
    var title: Text {
        switch self {
        case .debug: Text("Debug", bundle: .module)
        case .info: Text("Info", bundle: .module)
        case .warning: Text("Warning", bundle: .module)
        case .error: Text("Error", bundle: .module)
        }
    }

    var symbolName: String {
        switch self {
        case .debug: "ant"
        case .info: "info.circle"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .debug, .info: .secondary
        case .warning: .orange
        case .error: .red
        }
    }
}
