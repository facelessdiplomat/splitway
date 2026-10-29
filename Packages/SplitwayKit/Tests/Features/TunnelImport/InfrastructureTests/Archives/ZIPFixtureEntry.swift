import Foundation
import ZIPFoundation

struct ZIPFixtureEntry {
    let path: String
    let type: Entry.EntryType
    let contents: Data
    let compressionMethod: CompressionMethod

    static func file(_ path: String, _ text: String) -> ZIPFixtureEntry {
        ZIPFixtureEntry(path: path, type: .file, contents: Data(text.utf8), compressionMethod: .deflate)
    }

    static func file(_ path: String, repeating byte: UInt8, count: Int) -> ZIPFixtureEntry {
        ZIPFixtureEntry(
            path: path,
            type: .file,
            contents: Data(repeating: byte, count: count),
            compressionMethod: .deflate
        )
    }

    static func storedFile(_ path: String, _ text: String) -> ZIPFixtureEntry {
        ZIPFixtureEntry(path: path, type: .file, contents: Data(text.utf8), compressionMethod: .none)
    }

    static func directory(_ path: String) -> ZIPFixtureEntry {
        ZIPFixtureEntry(path: path, type: .directory, contents: Data(), compressionMethod: .none)
    }

    static func symlink(_ path: String, to target: String) -> ZIPFixtureEntry {
        ZIPFixtureEntry(path: path, type: .symlink, contents: Data(target.utf8), compressionMethod: .none)
    }
}
