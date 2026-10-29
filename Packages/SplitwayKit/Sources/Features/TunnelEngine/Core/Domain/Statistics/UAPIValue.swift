import TunnelConfiguration

enum UAPIValue {
    static func keyAndValue(in line: Substring) throws(UAPIResponseError) -> (key: Substring, value: Substring) {
        guard let separator = line.firstIndex(of: "=") else { throw .malformedResponse }
        return (line[..<separator], line[line.index(after: separator)...])
    }

    static func number<Number: FixedWidthInteger>(_ value: Substring) throws(UAPIResponseError) -> Number {
        guard let number = Number(value) else { throw .malformedResponse }
        return number
    }

    static func publicKey(_ value: Substring) throws(UAPIResponseError) -> PublicKey {
        guard let publicKey = try? PublicKey(hexEncoded: String(value)) else { throw .malformedResponse }
        return publicKey
    }
}
