import Foundation

struct WireGuardKey: Sendable, Hashable {
    static let byteCount = 32
    private static let base64Length = 44
    private static let hexadecimalDigitsPerByte = 2
    private static let hexadecimalRadix = 16

    let bytes: [UInt8]

    init(validatedBytes: [UInt8]) {
        bytes = validatedBytes
    }

    init(base64Encoded text: String) throws(WireGuardKeyParsingError) {
        guard text.utf8.count == Self.base64Length,
            let decoded = Data(base64Encoded: text),
            decoded.base64EncodedString() == text
        else { throw .malformedBase64 }
        guard decoded.count == Self.byteCount else { throw .invalidLength }
        bytes = Array(decoded)
    }

    init(hexEncoded text: String) throws(WireGuardKeyParsingError) {
        let digits = Array(text)
        guard digits.count == Self.byteCount * Self.hexadecimalDigitsPerByte,
            digits.allSatisfy({ digit in digit.isASCII && digit.isHexDigit })
        else { throw .malformedHex }
        bytes = stride(from: 0, to: digits.count, by: Self.hexadecimalDigitsPerByte).compactMap { index in
            UInt8(String(digits[index..<index + Self.hexadecimalDigitsPerByte]), radix: Self.hexadecimalRadix)
        }
    }

    var base64EncodedText: String {
        Data(bytes).base64EncodedString()
    }

    var hexEncodedText: String {
        bytes.map { byte in
            let digits = String(byte, radix: Self.hexadecimalRadix)
            return digits.count == 1 ? "0" + digits : digits
        }
        .joined()
    }
}
