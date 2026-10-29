import Foundation
import Testing
import ZIPFoundation

enum ZIPFixture {
    private static let localHeaderUncompressedSizeOffset = 22
    private static let localHeaderNameLengthOffset = 26
    private static let localHeaderExtraFieldLengthOffset = 28
    private static let localHeaderLength = 30
    private static let centralHeaderUncompressedSizeOffset = 24
    private static let endRecordLength = 22
    private static let endRecordCentralDirectoryStartOffset = 16

    static func archive(_ entries: [ZIPFixtureEntry]) throws -> Data {
        let archive = try Archive(accessMode: .create)
        for entry in entries {
            try archive.addEntry(
                with: entry.path,
                type: entry.type,
                uncompressedSize: Int64(entry.contents.count),
                compressionMethod: entry.compressionMethod,
                provider: { position, size in entry.contents.subdata(in: Int(position)..<Int(position) + size) }
            )
        }
        return try #require(archive.data)
    }

    static func understatingUncompressedSize(ofOnlyEntryIn archive: Data, as declaredSize: UInt32) -> Data {
        let centralDirectoryStartField = archive.count - endRecordLength + endRecordCentralDirectoryStartOffset
        let centralHeaderStart = Int(littleEndianInteger(UInt32.self, in: archive, at: centralDirectoryStartField))
        let centralHeaderSizeField = centralHeaderStart + centralHeaderUncompressedSizeOffset
        var patched = archive
        replaceLittleEndianInteger(declaredSize, in: &patched, at: localHeaderUncompressedSizeOffset)
        replaceLittleEndianInteger(declaredSize, in: &patched, at: centralHeaderSizeField)
        return patched
    }

    static func corruptingFirstContentByte(ofOnlyStoredEntryIn archive: Data) -> Data {
        let nameLength = Int(littleEndianInteger(UInt16.self, in: archive, at: localHeaderNameLengthOffset))
        let extraFieldLength = Int(littleEndianInteger(UInt16.self, in: archive, at: localHeaderExtraFieldLengthOffset))
        let contentOffset = localHeaderLength + nameLength + extraFieldLength
        var patched = archive
        patched[contentOffset] ^= 0xFF
        return patched
    }

    private static func littleEndianInteger<Integer: FixedWidthInteger>(
        _ type: Integer.Type,
        in data: Data,
        at offset: Int
    ) -> Integer {
        (0..<Integer.bitWidth / 8).reduce(Integer.zero) { value, byteIndex in
            value | Integer(data[offset + byteIndex]) << (8 * byteIndex)
        }
    }

    private static func replaceLittleEndianInteger<Integer: FixedWidthInteger>(
        _ value: Integer,
        in data: inout Data,
        at offset: Int
    ) {
        withUnsafeBytes(of: value.littleEndian) { bytes in
            data.replaceSubrange(offset..<offset + bytes.count, with: bytes)
        }
    }
}
