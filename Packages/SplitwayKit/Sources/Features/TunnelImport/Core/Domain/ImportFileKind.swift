import Foundation

enum ImportFileKind {
    case archive
    case configurationText

    private static let archiveSignatures: [[UInt8]] = [[0x50, 0x4B, 0x03, 0x04], [0x50, 0x4B, 0x05, 0x06]]
    private static let archiveFileExtension = ".zip"

    init(fileName: String, contents: Data) {
        let startsLikeArchive = Self.archiveSignatures.contains { signature in contents.starts(with: signature) }
        let namedLikeArchive = fileName.lowercased().hasSuffix(Self.archiveFileExtension)
        self = startsLikeArchive || namedLikeArchive ? .archive : .configurationText
    }
}
