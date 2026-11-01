import Foundation
import dnssd

enum ResolverIdentityProbe {
    static let resolverEchoName = "o-o.myaddr.l.google.com"
    private static let answerTimeout: TimeInterval = 10
    private static let pollMilliseconds: Int32 = 250

    static func resolverEcho() -> [String] {
        let answers = TextRecordAnswers()
        var reference: DNSServiceRef?
        let status = DNSServiceQueryRecord(
            &reference, 0, 0, resolverEchoName, UInt16(kDNSServiceType_TXT), UInt16(kDNSServiceClass_IN),
            receiveTextRecord, Unmanaged.passUnretained(answers).toOpaque()
        )
        guard status == kDNSServiceErr_NoError, let reference else { return [] }
        defer { DNSServiceRefDeallocate(reference) }
        let deadline = Date().addingTimeInterval(answerTimeout)
        while answers.texts.isEmpty, Date() < deadline {
            var socket = pollfd(fd: DNSServiceRefSockFD(reference), events: Int16(POLLIN), revents: 0)
            if poll(&socket, 1, pollMilliseconds) > 0 {
                DNSServiceProcessResult(reference)
            }
        }
        return answers.texts.sorted()
    }
}

private final class TextRecordAnswers {
    var texts: [String] = []
}

private let receiveTextRecord: DNSServiceQueryRecordReply = { _, _, _, error, _, _, _, length, data, _, context in
    guard error == kDNSServiceErr_NoError, let data, let context else { return }
    let answers = Unmanaged<TextRecordAnswers>.fromOpaque(context).takeUnretainedValue()
    var remaining = UnsafeRawBufferPointer(start: data, count: Int(length))[...]
    while let count = remaining.first.map(Int.init), remaining.count > count {
        if let text = String(bytes: remaining.dropFirst().prefix(count), encoding: .utf8) {
            answers.texts.append(text)
        }
        remaining = remaining.dropFirst(count + 1)
    }
}
