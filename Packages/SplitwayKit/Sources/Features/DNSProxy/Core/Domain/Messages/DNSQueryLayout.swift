struct DNSQueryLayout {
    struct ExtendedDNS: Equatable {
        let acceptsDNSSECRecords: Bool
    }

    private struct RecordHeader {
        let type: UInt16
        let timeToLive: UInt32
    }

    let questionSectionEnd: Int
    let extendedDNS: ExtendedDNS?

    init(parsing query: [UInt8]) throws(DNSMessageError) {
        guard query.count >= DNSWireFormat.headerByteCount else { throw .truncatedHeader }
        guard query[DNSWireFormat.firstFlagsOffset] & DNSWireFormat.queryResponseFlag == 0 else { throw .notAQuery }
        var reader = DNSMessageReader(query, offset: DNSWireFormat.headerByteCount)
        try Self.skipQuestions(DNSWireFormat.count(at: DNSWireFormat.questionCountOffset, in: query), with: &reader)
        questionSectionEnd = reader.offset
        let recordCount =
            DNSWireFormat.count(at: DNSWireFormat.answerCountOffset, in: query)
            + DNSWireFormat.count(at: DNSWireFormat.authorityCountOffset, in: query)
        for _ in 0..<recordCount {
            _ = try Self.readRecord(with: &reader)
        }
        extendedDNS = try Self.extendedDNS(
            amongAdditionalRecords: DNSWireFormat.count(at: DNSWireFormat.additionalCountOffset, in: query),
            with: &reader
        )
    }

    private static func skipQuestions(_ count: Int, with reader: inout DNSMessageReader) throws(DNSMessageError) {
        for _ in 0..<count {
            guard reader.skipName(), reader.skip(DNSWireFormat.questionFieldsByteCount) else {
                throw .malformedQuestion
            }
        }
    }

    private static func extendedDNS(
        amongAdditionalRecords count: Int,
        with reader: inout DNSMessageReader
    ) throws(DNSMessageError) -> ExtendedDNS? {
        var extendedDNS: ExtendedDNS?
        for _ in 0..<count {
            let record = try readRecord(with: &reader)
            if record.type == DNSWireFormat.optionRecordType {
                let flags = UInt16(truncatingIfNeeded: record.timeToLive)
                extendedDNS = ExtendedDNS(acceptsDNSSECRecords: flags & DNSWireFormat.dnssecOKFlag != 0)
            }
        }
        return extendedDNS
    }

    private static func readRecord(with reader: inout DNSMessageReader) throws(DNSMessageError) -> RecordHeader {
        guard reader.skipName(), let type = reader.readUInt16(), reader.skip(DNSWireFormat.recordClassByteCount),
            let timeToLive = reader.readUInt32(), let dataByteCount = reader.readUInt16(),
            reader.skip(Int(dataByteCount))
        else { throw .malformedRecord }
        return RecordHeader(type: type, timeToLive: timeToLive)
    }
}
