import Foundation

public struct ArchivedConfigurationFile: Sendable, Hashable {
    public let fileName: String
    public let contents: Data

    public init(fileName: String, contents: Data) {
        self.fileName = fileName
        self.contents = contents
    }
}
