import SharedKernelTestSupport
import TransparentProxy

public final class ScriptedDatagramFlow: ProxiedDatagramFlow {
    public typealias ReadCompletion = @Sendable (Result<[ProxiedDatagram], ProxiedFlowError>) -> Void
    public typealias WriteCompletion = @Sendable (ProxiedFlowError?) -> Void

    public struct Snapshot: Sendable {
        public var isOpened = false
        public var writtenDatagrams: [ProxiedDatagram] = []
        public var readClosings: [ProxiedFlowError?] = []
        public var writeClosings: [ProxiedFlowError?] = []
        public var heldWriteCompletions: [WriteCompletion] = []
        var pendingReads: [Result<[ProxiedDatagram], ProxiedFlowError>] = []
        var waitingRead: ReadCompletion?
    }

    public let state = AwaitableState(Snapshot())
    private let holdsWrites: Bool

    public init(holdsWrites: Bool = false) {
        self.holdsWrites = holdsWrites
    }

    public func open(completion: @escaping @Sendable (ProxiedFlowError?) -> Void) {
        state.update { snapshot in snapshot.isOpened = true }
        completion(nil)
    }

    public func readDatagrams(completion: @escaping ReadCompletion) {
        let next = state.update { snapshot -> Result<[ProxiedDatagram], ProxiedFlowError>? in
            guard !snapshot.pendingReads.isEmpty else {
                snapshot.waitingRead = completion
                return nil
            }
            return snapshot.pendingReads.removeFirst()
        }
        if let next {
            completion(next)
        }
    }

    public func writeDatagrams(_ datagrams: [ProxiedDatagram], completion: @escaping WriteCompletion) {
        let completesNow = state.update { snapshot -> Bool in
            snapshot.writtenDatagrams += datagrams
            guard holdsWrites else { return true }
            snapshot.heldWriteCompletions.append(completion)
            return false
        }
        if completesNow {
            completion(nil)
        }
    }

    public func closeRead(with error: ProxiedFlowError?) {
        state.update { snapshot in snapshot.readClosings.append(error) }
    }

    public func closeWrite(with error: ProxiedFlowError?) {
        state.update { snapshot in snapshot.writeClosings.append(error) }
    }

    public func send(_ datagrams: [ProxiedDatagram]) {
        push(.success(datagrams))
    }

    public func closeFromTheApp() {
        push(.success([]))
    }

    public func releaseHeldWrites() {
        let held = state.update { snapshot -> [WriteCompletion] in
            defer { snapshot.heldWriteCompletions.removeAll() }
            return snapshot.heldWriteCompletions
        }
        for completion in held {
            completion(nil)
        }
    }

    private func push(_ read: Result<[ProxiedDatagram], ProxiedFlowError>) {
        let waiting = state.update { snapshot -> ReadCompletion? in
            guard let waiting = snapshot.waitingRead else {
                snapshot.pendingReads.append(read)
                return nil
            }
            snapshot.waitingRead = nil
            return waiting
        }
        waiting?(read)
    }
}
