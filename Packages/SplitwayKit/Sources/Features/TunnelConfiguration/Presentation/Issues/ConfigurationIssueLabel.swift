import DesignSystemPresentation
import SwiftUI
import TunnelConfiguration

public struct ConfigurationIssueLabel: View {
    private let issue: ConfigurationIssue

    public init(_ issue: ConfigurationIssue) {
        self.issue = issue
    }

    public var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(issue.kind.message)
                if let line = issue.line {
                    Text("Line \(line)", bundle: .module)
                        .font(.caption)
                        .foregroundStyle(.supportingText)
                }
            }
        } icon: {
            Image(systemName: issue.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(issue.severity == .error ? .red : .orange)
        }
        .font(.subheadline)
    }
}
