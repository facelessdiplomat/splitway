import ServiceCatalog
import SwiftUI

extension ServiceTint {
    private static let channelMaximum = 255.0

    var color: Color {
        Color(
            red: Double(red) / Self.channelMaximum,
            green: Double(green) / Self.channelMaximum,
            blue: Double(blue) / Self.channelMaximum
        )
    }
}
