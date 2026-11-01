import ServiceCatalog
import SwiftUI

struct ServiceIconView: View {
    private static let cornerRadius: CGFloat = 7

    let icon: ServiceIcon
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 30

    var body: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
            .fill(icon.tint.color)
            .frame(width: side, height: side)
            .overlay {
                Text(verbatim: icon.monogram)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}
