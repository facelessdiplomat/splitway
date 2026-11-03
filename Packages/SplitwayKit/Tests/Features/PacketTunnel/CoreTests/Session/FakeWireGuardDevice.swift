import Synchronization
import TunnelEngine

final class FakeWireGuardDevice: WireGuardDeviceEngine, RunningWireGuardDevice {
    private let log: SessionEventLog
    private let startFailure: TunnelEngineError?
    private let configurations = Mutex<[UAPIConfiguration]>([])

    init(log: SessionEventLog, startFailure: TunnelEngineError?) {
        self.log = log
        self.startFailure = startFailure
    }

    var receivedConfigurations: [UAPIConfiguration] {
        configurations.withLock { configurations in configurations }
    }

    func startDevice(
        tunnelFileDescriptor: Int32,
        configuration: UAPIConfiguration
    ) throws(TunnelEngineError) -> any RunningWireGuardDevice {
        if let startFailure {
            throw startFailure
        }
        configurations.withLock { configurations in configurations.append(configuration) }
        log.record(.startedDevice(descriptor: tunnelFileDescriptor))
        return self
    }

    func apply(_ configuration: UAPIConfiguration) throws(TunnelEngineError) {
        configurations.withLock { configurations in configurations.append(configuration) }
        log.record(.appliedConfiguration)
    }

    func runtimeStatistics() throws(TunnelEngineError) -> RuntimeStatistics {
        RuntimeStatistics(peers: [])
    }

    func bumpSockets() throws(TunnelEngineError) {
        log.record(.bumpedSockets)
    }

    func stop() {
        log.record(.stoppedDevice)
    }
}
