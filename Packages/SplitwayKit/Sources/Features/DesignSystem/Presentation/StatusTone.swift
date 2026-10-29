import SwiftUI

public enum StatusTone: Sendable, Hashable, CaseIterable {
    case neutral
    case positive
    case progress
    case warning
    case critical

    var color: Color {
        switch self {
        case .neutral: .secondary
        case .positive: .green
        case .progress: .blue
        case .warning: .orange
        case .critical: .red
        }
    }

    var symbolName: String {
        switch self {
        case .neutral: "circle"
        case .positive: "checkmark.circle.fill"
        case .progress: "arrow.triangle.2.circlepath"
        case .warning: "exclamationmark.triangle.fill"
        case .critical: "xmark.octagon.fill"
        }
    }
}
