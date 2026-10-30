import Foundation
import SharedKernel
import Synchronization
import TunnelEngine

public final class TCPFlowRelay: Sendable {
    public static let windowChunkCount = 4

    private let flow: any ProxiedStreamFlow
    private let destination: UserspaceNetworkDestination
    private let network: any RunningUserspaceNetwork
    private let policy: TCPRelayPolicy
    private let clock: any WallClock
    private let queue: DispatchQueue
    private let progress: Mutex<TCPRelayProgress>

    public init(
        flow: any ProxiedStreamFlow,
        destination: UserspaceNetworkDestination,
        network: any RunningUserspaceNetwork,
        policy: TCPRelayPolicy,
        environment: RelayEnvironment
    ) {
        self.flow = flow
        self.destination = destination
        self.network = network
        self.policy = policy
        clock = environment.clock
        queue = DispatchQueue(label: "Splitway.TCPFlowRelay", target: environment.targetQueue)
        progress = Mutex(TCPRelayProgress(startingAt: environment.clock.now()))
    }

    public func start(onFinish: @escaping @Sendable () -> Void) {
        let now = clock.now()
        progress.withLock { progress in progress.start(at: now, onFinish: onFinish) }
        queue.async { self.connect() }
    }

    public func cancel() {
        abort(with: .aborted)
    }

    public func closeIfIdle(at moment: Date) -> Bool {
        guard progress.withLock({ progress in progress.isIdle(at: moment, timeout: policy.idleTimeout) }) else {
            return false
        }
        abort(with: .timedOut)
        return true
    }

    func deliverToApp(_ bytes: UnsafeRawBufferPointer) {
        let data = Data(bytes)
        let now = clock.now()
        guard progress.withLock({ progress in progress.beginAppWrite(at: now) }) else { return }
        flow.write(data) { error in
            if let error {
                self.abort(with: error)
            } else {
                self.completeAppWrite(of: data.count)
            }
        }
    }

    func endFromTunnel(with error: UserspaceNetworkError?) {
        guard error == nil else {
            abort(with: .peerReset)
            return
        }
        if progress.withLock({ progress in progress.endTunnel() }) {
            closeAppWrite()
        }
    }

    private func connect() {
        let connection: any UserspaceConnection
        do {
            connection = try network.dialTCP(to: destination, timeout: policy.connectTimeout)
        } catch {
            abort(with: Self.dialFailure(error))
            return
        }
        guard progress.withLock({ progress in progress.adopt(connection) }) else {
            connection.close(.both)
            return
        }
        flow.open { error in
            self.queue.async {
                if let error {
                    self.abort(with: error)
                } else {
                    self.startPumps(through: connection)
                }
            }
        }
    }

    private func startPumps(through connection: any UserspaceConnection) {
        do {
            try connection.startReceiving(
                into: self,
                readByteCount: policy.chunkByteCount,
                initialCredit: policy.chunkByteCount * Self.windowChunkCount
            )
        } catch {
            abort(with: .aborted)
            return
        }
        readFromApp()
    }

    private func readFromApp() {
        flow.read { result in
            self.queue.async { self.forwardToTunnel(result) }
        }
    }

    private func forwardToTunnel(_ result: Result<Data, ProxiedFlowError>) {
        guard let connection = progress.withLock({ progress in progress.activeConnection }) else { return }
        switch result {
        case .failure(let error):
            abort(with: error)
        case .success(let data) where data.isEmpty:
            connection.close(.write)
            endFromApp()
        case .success(let data):
            let written = data.withUnsafeBytes { bytes in
                Result { () throws(UserspaceNetworkError) in try connection.write(bytes) }
            }
            guard case .success = written else {
                abort(with: .peerReset)
                return
            }
            let now = clock.now()
            progress.withLock { progress in progress.recordActivity(at: now) }
            readFromApp()
        }
    }

    private func completeAppWrite(of byteCount: Int) {
        let (connection, closesAppWrite) = progress.withLock { progress in
            (progress.connection, progress.completeAppWrite())
        }
        connection?.grant(byteCount)
        if closesAppWrite {
            closeAppWrite()
        }
    }

    private func closeAppWrite() {
        flow.closeWrite(with: nil)
        finishIfBothSidesEnded()
    }

    private func endFromApp() {
        progress.withLock { progress in progress.endApp() }
        finishIfBothSidesEnded()
    }

    private func finishIfBothSidesEnded() {
        guard let finishing = progress.withLock({ progress in progress.finishIfBothSidesEnded() }) else { return }
        finishing.closeConnections()
        flow.closeRead(with: nil)
        finishing.onFinish?()
    }

    private func abort(with error: ProxiedFlowError) {
        guard let finishing = progress.withLock({ progress in progress.finish() }) else { return }
        finishing.closeConnections()
        flow.closeRead(with: error)
        flow.closeWrite(with: error)
        finishing.onFinish?()
    }

    private static func dialFailure(_ error: UserspaceNetworkError) -> ProxiedFlowError {
        switch error {
        case .connectionFailed: .refused
        case .timedOut: .timedOut
        default: .aborted
        }
    }
}
