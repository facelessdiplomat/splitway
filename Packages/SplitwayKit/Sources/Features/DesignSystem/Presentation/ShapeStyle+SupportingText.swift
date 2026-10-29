import SwiftUI

extension ShapeStyle where Self == Color {
    public static var supportingText: Color {
        Color("SupportingText", bundle: .module)
    }
}
