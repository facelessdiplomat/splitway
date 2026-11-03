import TunnelCoreFramework
import TunnelEngine

final class TunnelCoreUserspaceConnection: UserspaceConnection {
    private let handle: Int32

    init(handle: Int32) {
        self.handle = handle
    }

    deinit {
        close(.both)
    }

    func startReceiving(
        into receiver: any UserspaceConnectionReceiver,
        readByteCount: Int,
        initialCredit: Int
    ) throws(UserspaceNetworkError) {
        let box = Unmanaged.passRetained(UserspaceConnectionReceiverBox(receiver: receiver))
        let callbacks = box.takeUnretainedValue().callbacks(retainedUntilFinish: box.toOpaque())
        let status = tc_connection_start_receiving(
            handle, callbacks, Int32(clamping: readByteCount), Int32(clamping: initialCredit))
        guard let error = UserspaceNetworkError(status: status, releasedHandle: .connectionClosed) else { return }
        box.release()
        throw error
    }

    func write(_ bytes: UnsafeRawBufferPointer) throws(UserspaceNetworkError) -> Int {
        guard let baseAddress = bytes.baseAddress else { return 0 }
        var writtenLength: Int32 = 0
        let status = tc_connection_write(
            handle, baseAddress.assumingMemoryBound(to: UInt8.self), Int32(clamping: bytes.count), &writtenLength)
        try UserspaceNetworkError.check(status, whenHandleIsReleased: .connectionClosed)
        return Int(writtenLength)
    }

    func grant(_ byteCount: Int) {
        _ = tc_connection_grant(handle, Int32(clamping: byteCount))
    }

    func close(_ closing: UserspaceConnectionClosing) {
        _ = tc_connection_close(handle, TCConnectionClosing(closing))
    }
}

extension TCConnectionClosing {
    fileprivate init(_ closing: UserspaceConnectionClosing) {
        switch closing {
        case .write: self = .write
        case .read: self = .read
        case .both: self = .both
        }
    }
}
