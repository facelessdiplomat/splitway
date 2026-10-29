import Foundation

public enum HandshakeRecency: Sendable, Hashable {
    case never
    case elapsed(Duration)

    init(latestHandshake: Date?, now: Date) {
        guard let latestHandshake else {
            self = .never
            return
        }
        let elapsedSeconds = max(0, now.timeIntervalSince(latestHandshake)).rounded(.down)
        self = .elapsed(.seconds(Int64(elapsedSeconds)))
    }
}
