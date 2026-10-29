import SharedKernel

enum EndpointParser {
    static func parse(_ text: String) throws(EndpointParsingError) -> Endpoint {
        if text.hasPrefix("[") {
            return try parseBracketedIPv6(text)
        }
        guard let separator = text.lastIndex(of: ":") else { throw .missingPort }
        let hostText = text[..<separator]
        guard !hostText.contains(":") else { throw .unbracketedIPv6 }
        return try Endpoint(host: parseHost(hostText), port: parsePort(text[text.index(after: separator)...]))
    }

    private static func parseBracketedIPv6(_ text: String) throws(EndpointParsingError) -> Endpoint {
        guard let closingBracket = text.firstIndex(of: "]") else { throw .invalidHost }
        let addressText = text[text.index(after: text.startIndex)..<closingBracket]
        guard let address = try? IPAddress(String(addressText)), address.family == .ipv6 else { throw .invalidHost }
        let remainder = text[text.index(after: closingBracket)...]
        guard remainder.hasPrefix(":") else { throw .missingPort }
        return try Endpoint(host: .address(address), port: parsePort(remainder.dropFirst()))
    }

    private static func parseHost(_ text: Substring) throws(EndpointParsingError) -> EndpointHost {
        if let address = try? IPAddress(String(text)) {
            return .address(address)
        }
        guard let name = try? DomainName(String(text)) else { throw .invalidHost }
        return .name(name)
    }

    private static func parsePort(_ text: Substring) throws(EndpointParsingError) -> NetworkPort {
        do {
            return try NetworkPort(String(text))
        } catch {
            throw .invalidPort(error)
        }
    }
}
