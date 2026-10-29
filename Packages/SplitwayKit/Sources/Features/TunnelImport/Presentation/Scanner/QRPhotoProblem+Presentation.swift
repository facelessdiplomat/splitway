import SwiftUI

extension QRPhotoProblem {
    var title: Text {
        switch self {
        case .noQRCode: Text("No QR code in the photo", bundle: .module)
        case .unreadableImage: Text("The photo can’t be read", bundle: .module)
        }
    }

    var message: Text {
        switch self {
        case .noQRCode: Text("Choose a photo where the whole QR code is visible.", bundle: .module)
        case .unreadableImage: Text("Choose another photo or scan the code with the camera.", bundle: .module)
        }
    }
}
