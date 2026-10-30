import Darwin
import Foundation
import SharedKernelTestSupport
import TransparentProxy

public final class ScriptedStreamFlow: ProxiedStreamFlow {
    public typealias ReadCompletion = @Sendable (Result<Data, ProxiedFlowError>) -> Void
    public typealias WriteCompletion = @Sendable (ProxiedFlowError?) -> Void

    public struct Snapshot: Sendable {
        public var isOpened = false
        public var writtenData: [Data] = []
        public var readClosings: [ProxiedFlowError?] = []
        public var writeClosings: [ProxiedFlowError?] = []
        public var heldWriteCompletions: [WriteCompletion] = []
        public var reentrantCallCount = 0
        var threadsCompletingWrites: Set<UInt32> = []
        var pendingReads: [Result<Data, ProxiedFlowError>] = []
        var waitingRead: ReadCompletion?

        public var writtenBytes: [UInt8] {
            writtenData.flatMap(Array.init)
        }
    }

    public let state = AwaitableState(Snapshot())
    private let openFailure: ProxiedFlowError?
    private let holdsWrites: Bool
    private let writeFailure: ProxiedFlowError?

    public init(openFailure: ProxiedFlowError? = nil, holdsWrites: Bool = false, writeFailure: ProxiedFlowError? = nil)
    {
        self.openFailure = openFailure
        self.holdsWrites = holdsWrites
        self.writeFailure = writeFailure
    }

    public func open(completion: @escaping @Sendable (ProxiedFlowError?) -> Void) {
        state.update { snapshot in snapshot.isOpened = true }
        completion(openFailure)
    }

    public func read(completion: @escaping ReadCompletion) {
        noteReentrance()
        let next = state.update { snapshot -> Result<Data, ProxiedFlowError>? in
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

    public func write(_ data: Data, completion: @escaping WriteCompletion) {
        noteReentrance()
        let completesNow = state.update { snapshot -> Bool in
            snapshot.writtenData.append(data)
            guard holdsWrites else { return true }
            snapshot.heldWriteCompletions.append(completion)
            return false
        }
        if completesNow {
            complete(completion, with: writeFailure)
        }
    }

    public func closeRead(with error: ProxiedFlowError?) {
        noteReentrance()
        state.update { snapshot in snapshot.readClosings.append(error) }
    }

    public func closeWrite(with error: ProxiedFlowError?) {
        noteReentrance()
        state.update { snapshot in snapshot.writeClosings.append(error) }
    }

    public func send(_ bytes: [UInt8]) {
        push(.success(Data(bytes)))
    }

    public func endStream() {
        push(.success(Data()))
    }

    public func fail(_ error: ProxiedFlowError) {
        push(.failure(error))
    }

    public func releaseHeldWrites() {
        let held = state.update { snapshot -> [WriteCompletion] in
            defer { snapshot.heldWriteCompletions.removeAll() }
            return snapshot.heldWriteCompletions
        }
        for completion in held {
            complete(completion, with: nil)
        }
    }

    private func complete(_ completion: WriteCompletion, with error: ProxiedFlowError?) {
        let thread = pthread_mach_thread_np(pthread_self())
        state.update { snapshot in _ = snapshot.threadsCompletingWrites.insert(thread) }
        completion(error)
        state.update { snapshot in _ = snapshot.threadsCompletingWrites.remove(thread) }
    }

    private func noteReentrance() {
        let thread = pthread_mach_thread_np(pthread_self())
        state.update { snapshot in
            if snapshot.threadsCompletingWrites.contains(thread) {
                snapshot.reentrantCallCount += 1
            }
        }
    }

    private func push(_ read: Result<Data, ProxiedFlowError>) {
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
