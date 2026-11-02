import Foundation

public protocol ChosenFileAccess: Sendable {
    func beginAccess(to files: [URL]) -> [URL]
    func endAccess(to files: [URL])
}
