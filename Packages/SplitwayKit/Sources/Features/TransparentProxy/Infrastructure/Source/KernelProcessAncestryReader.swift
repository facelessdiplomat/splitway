import Darwin
import Foundation
import Security
import TransparentProxy

public struct KernelProcessAncestryReader: ProcessAncestryReader {
    private static let microsecondsPerSecond: UInt64 = 1_000_000

    public init() {}

    public func launcher(of processIdentifier: Int32) -> RunningProcess? {
        guard let process = Self.processInformation(of: processIdentifier) else { return nil }
        let parentIdentifier = process.kp_eproc.e_ppid
        guard let parent = Self.processInformation(of: parentIdentifier) else { return nil }
        return RunningProcess(identifier: parentIdentifier, startTime: Self.startTime(of: parent))
    }

    public func codeIdentity(of process: RunningProcess) throws(CodeIdentityReadingError) -> CodeIdentity {
        let attributes = [kSecGuestAttributePid as String: NSNumber(value: process.identifier)] as CFDictionary
        var code: SecCode?
        guard SecCodeCopyGuestWithAttributes(nil, attributes, [], &code) == errSecSuccess, let code else {
            throw .processUnavailable
        }
        let identity = try SecurityCodeIdentityReader.codeIdentity(of: code)
        guard let current = Self.processInformation(of: process.identifier),
            Self.startTime(of: current) == process.startTime
        else { throw .processUnavailable }
        return identity
    }

    private static func processInformation(of processIdentifier: Int32) -> kinfo_proc? {
        var information = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var request: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, processIdentifier]
        guard sysctl(&request, UInt32(request.count), &information, &size, nil, 0) == 0, size > 0 else {
            return nil
        }
        return information
    }

    private static func startTime(of information: kinfo_proc) -> UInt64 {
        let start = information.kp_proc.p_un.__p_starttime
        return UInt64(start.tv_sec) * microsecondsPerSecond + UInt64(start.tv_usec)
    }
}
