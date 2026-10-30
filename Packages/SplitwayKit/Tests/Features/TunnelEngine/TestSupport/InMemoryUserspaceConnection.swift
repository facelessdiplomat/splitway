import SharedKernelTestSupport
import TunnelEngine

public final class InMemoryUserspaceConnection: UserspaceConnection {
    public struct Snapshot: Sendable {
        public var writtenChunks: [[UInt8]] = []
        public var closings: [UserspaceConnectionClosing] = []
        public var grantedByteCount = 0
        public var initialCredit: Int?
        public var readByteCount: Int?
        public var receiver: (any UserspaceConnectionReceiver)?

        public var writtenBytes: [UInt8] {
            writtenChunks.flatMap(\.self)
        }
    }

    public let destination: UserspaceNetworkDestination
    public let state = AwaitableState(Snapshot())
    private let writeFailure: UserspaceNetworkError?

    public init(destination: UserspaceNetworkDestination, writeFailure: UserspaceNetworkError? = nil) {
        self.destination = destination
        self.writeFailure = writeFailure
    }

    public func startReceiving(
        into receiver: any UserspaceConnectionReceiver,
        readByteCount: Int,
        initialCredit: Int
    ) throws(UserspaceNetworkError) {
        state.update { snapshot in
            snapshot.receiver = receiver
            snapshot.readByteCount = readByteCount
            snapshot.initialCredit = initialCredit
        }
    }

    public func write(_ bytes: UnsafeRawBufferPointer) throws(UserspaceNetworkError) -> Int {
        if let writeFailure {
            throw writeFailure
        }
        let chunk = Array(bytes)
        state.update { snapshot in snapshot.writtenChunks.append(chunk) }
        return chunk.count
    }

    public func grant(_ byteCount: Int) {
        state.update { snapshot in snapshot.grantedByteCount += byteCount }
    }

    public func close(_ closing: UserspaceConnectionClosing) {
        state.update { snapshot in snapshot.closings.append(closing) }
    }

    public func deliver(_ bytes: [UInt8]) {
        bytes.withUnsafeBytes { buffer in state.current.receiver?.receive(buffer) }
    }

    public func finishReceiving(with error: UserspaceNetworkError?) {
        state.current.receiver?.finish(error)
    }
}
