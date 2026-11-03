import TunnelCoreFramework
import TunnelEngine

final class UserspaceConnectionReceiverBox: Sendable {
    let receiver: any UserspaceConnectionReceiver

    init(receiver: any UserspaceConnectionReceiver) {
        self.receiver = receiver
    }

    func callbacks(retainedUntilFinish context: UnsafeMutableRawPointer) -> TCConnectionCallbacks {
        TCConnectionCallbacks(receive: deliverReceivedBytes, finish: deliverFinish, context: context)
    }
}

private func deliverReceivedBytes(context: UnsafeMutableRawPointer?, bytes: UnsafePointer<UInt8>, length: Int32) {
    guard let context else { return }
    let box = Unmanaged<UserspaceConnectionReceiverBox>.fromOpaque(context).takeUnretainedValue()
    box.receiver.receive(UnsafeRawBufferPointer(start: bytes, count: Int(length)))
}

private func deliverFinish(context: UnsafeMutableRawPointer?, status: TCStatus) {
    guard let context else { return }
    let box = Unmanaged<UserspaceConnectionReceiverBox>.fromOpaque(context).takeRetainedValue()
    box.receiver.finish(UserspaceNetworkError(finishing: status))
}
