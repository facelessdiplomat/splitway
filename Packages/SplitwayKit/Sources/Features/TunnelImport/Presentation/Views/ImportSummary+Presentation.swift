import SwiftUI

extension ImportSummary {
    var message: Text {
        Text("Imported \(importedCount) of \(totalCount)", bundle: .module)
    }
}
