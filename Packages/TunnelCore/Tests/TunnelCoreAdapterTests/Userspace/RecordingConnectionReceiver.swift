import TunnelEngine

final class RecordingConnectionReceiver: UserspaceConnectionReceiver {
    enum Event: Sendable {
        case received([UInt8])
        case finished(UserspaceNetworkError?)
    }

    struct Finish: Sendable {
        let bytes: [UInt8]
        let error: UserspaceNetworkError?
    }

    private let events: AsyncStream<Event>
    private let continuation: AsyncStream<Event>.Continuation

    init() {
        (events, continuation) = AsyncStream.makeStream()
    }

    func receive(_ bytes: UnsafeRawBufferPointer) {
        continuation.yield(.received(Array(bytes)))
    }

    func finish(_ error: UserspaceNetworkError?) {
        continuation.yield(.finished(error))
        continuation.finish()
    }

    func bytes(count: Int) async -> [UInt8] {
        var bytes: [UInt8] = []
        for await event in events {
            if case .received(let chunk) = event {
                bytes += chunk
            }
            if bytes.count >= count {
                break
            }
        }
        return bytes
    }

    func finishing() async -> Finish? {
        var bytes: [UInt8] = []
        for await event in events {
            switch event {
            case .received(let chunk):
                bytes += chunk
            case .finished(let error):
                return Finish(bytes: bytes, error: error)
            }
        }
        return nil
    }
}
