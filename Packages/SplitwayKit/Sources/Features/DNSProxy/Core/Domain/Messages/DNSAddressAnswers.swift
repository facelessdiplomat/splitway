import SharedKernel

public struct DNSAddressAnswers: Sendable, Hashable {
    private static let addressByteCounts: [UInt16: Int] = [
        DNSWireFormat.addressRecordType: 4,
        DNSWireFormat.ipv6AddressRecordType: 16,
    ]

    public let name: DomainName
    public let records: [DNSAddressRecord]

    public init(parsing response: [UInt8]) throws(DNSMessageError) {
        guard response.count >= DNSWireFormat.headerByteCount else { throw .truncatedHeader }
        guard response[DNSWireFormat.firstFlagsOffset] & DNSWireFormat.queryResponseFlag != 0 else {
            throw .notAResponse
        }
        guard DNSWireFormat.count(at: DNSWireFormat.questionCountOffset, in: response) == 1 else {
            throw .malformedQuestion
        }
        var reader = DNSMessageReader(response, offset: DNSWireFormat.headerByteCount)
        guard let questionName = reader.readName(), reader.skip(DNSWireFormat.questionFieldsByteCount),
            let name = try? DomainName(questionName)
        else { throw .malformedQuestion }
        self.name = name
        let responseCode = response[DNSWireFormat.secondFlagsOffset] & DNSWireFormat.responseCodeMask
        guard responseCode == DNSWireFormat.noErrorResponseCode else {
            records = []
            return
        }
        records = try Self.addressRecords(
            amongAnswers: DNSWireFormat.count(at: DNSWireFormat.answerCountOffset, in: response),
            with: &reader
        )
    }

    private static func addressRecords(
        amongAnswers count: Int,
        with reader: inout DNSMessageReader
    ) throws(DNSMessageError) -> [DNSAddressRecord] {
        var records: [DNSAddressRecord] = []
        for _ in 0..<count {
            guard reader.skipName(), let type = reader.readUInt16(), let recordClass = reader.readUInt16(),
                let timeToLive = reader.readUInt32(), let dataByteCount = reader.readUInt16()
            else { throw .malformedRecord }
            let dataStart = reader.offset
            guard reader.skip(Int(dataByteCount)) else { throw .malformedRecord }
            guard recordClass == DNSWireFormat.internetClass, addressByteCounts[type] == Int(dataByteCount),
                let address = IPAddress(networkOrderBytes: reader.bytes(in: dataStart..<reader.offset))
            else { continue }
            records.append(DNSAddressRecord(address: address, timeToLive: timeToLive))
        }
        return records
    }
}
