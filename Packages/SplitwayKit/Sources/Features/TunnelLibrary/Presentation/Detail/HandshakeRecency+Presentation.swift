import SwiftUI

extension HandshakeRecency {
    private static let elapsedStyle = Duration.UnitsFormatStyle.units(
        allowed: [.hours, .minutes, .seconds],
        width: .abbreviated,
        maximumUnitCount: 1
    )

    var text: Text {
        switch self {
        case .never: Text("No handshake yet", bundle: .module)
        case .elapsed(let duration): Self.elapsedText(duration)
        }
    }

    private static func elapsedText(_ duration: Duration) -> Text {
        let elapsed = duration.formatted(elapsedStyle)
        return Text("\(elapsed) ago", bundle: .module)
    }
}
