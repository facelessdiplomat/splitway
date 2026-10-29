import SwiftUI

extension View {
    func plainTextInput() -> some View {
        #if os(iOS)
            autocorrectionDisabled().textInputAutocapitalization(.never)
        #else
            autocorrectionDisabled()
        #endif
    }
}
