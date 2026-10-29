public enum DNSRefusalResponseBuilder {
    private static let opcodeAndRecursionDesiredMask: UInt8 = 0x79
    private static let checkingDisabledFlag: UInt8 = 0x10
    private static let refusedResponseCode: UInt8 = 5
    private static let advertisedUDPPayloadByteCount: UInt16 = 1232
    private static let rootName: [UInt8] = [0]
    private static let emptyAnswerAndAuthorityCounts: [UInt8] = [0, 0, 0, 0]
    private static let extendedResponseCodeAndVersion: [UInt8] = [0, 0]
    private static let emptyOptionData: [UInt8] = [0, 0]

    public static func response(refusing query: [UInt8]) throws(DNSMessageError) -> [UInt8] {
        let layout = try DNSQueryLayout(parsing: query)
        var response = Array(query[DNSWireFormat.identifierRange])
        response.append(
            DNSWireFormat.queryResponseFlag | query[DNSWireFormat.firstFlagsOffset] & opcodeAndRecursionDesiredMask)
        response.append(query[DNSWireFormat.secondFlagsOffset] & checkingDisabledFlag | refusedResponseCode)
        response += query[DNSWireFormat.questionCountRange]
        response += emptyAnswerAndAuthorityCounts
        response += DNSWireFormat.bytes(of: layout.extendedDNS == nil ? 0 : 1)
        response += query[DNSWireFormat.headerByteCount..<layout.questionSectionEnd]
        if let extendedDNS = layout.extendedDNS {
            response += optionRecord(answering: extendedDNS)
        }
        return response
    }

    private static func optionRecord(answering request: DNSQueryLayout.ExtendedDNS) -> [UInt8] {
        let flags = request.acceptsDNSSECRecords ? DNSWireFormat.dnssecOKFlag : 0
        var record = rootName
        record += DNSWireFormat.bytes(of: DNSWireFormat.optionRecordType)
        record += DNSWireFormat.bytes(of: advertisedUDPPayloadByteCount)
        record += extendedResponseCodeAndVersion
        record += DNSWireFormat.bytes(of: flags)
        record += emptyOptionData
        return record
    }
}
