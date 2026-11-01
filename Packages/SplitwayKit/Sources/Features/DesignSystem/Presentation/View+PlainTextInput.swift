import SwiftUI

extension View {
    public func plainTextInput() -> some View {
        #if os(iOS)
            autocorrectionDisabled().textInputAutocapitalization(.never)
        #else
            autocorrectionDisabled()
        #endif
    }
}
