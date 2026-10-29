import DesignSystemPresentation
import SwiftUI

public struct SystemExtensionWizardView: View {
    private static let spacing: CGFloat = 16

    private let model: SystemExtensionWizardModel
    private let install: @MainActor () async -> Void

    public init(model: SystemExtensionWizardModel, install: (@MainActor () async -> Void)? = nil) {
        self.model = model
        self.install = install ?? { await model.install() }
    }

    public var body: some View {
        VStack(spacing: Self.spacing) {
            Image(systemName: model.step.symbolName)
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            model.step.title
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            model.step.message
                .foregroundStyle(.supportingText)
                .multilineTextAlignment(.center)
            SystemExtensionWizardActions(step: model.step, install: install)
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
}
