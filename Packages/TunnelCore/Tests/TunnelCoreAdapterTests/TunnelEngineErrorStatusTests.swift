import Testing
import TunnelCoreFramework
import TunnelEngine

@testable import TunnelCoreAdapter

@Suite
struct TunnelEngineErrorStatusTests {
    @Test(arguments: [
        (TCStatus.invalidArgument, TunnelEngineError.internalFailure),
        (TCStatus.unknownHandle, TunnelEngineError.deviceNotRunning),
        (TCStatus.tunnelInterfaceUnavailable, TunnelEngineError.tunnelInterfaceUnavailable),
        (TCStatus.configurationRejected, TunnelEngineError.configurationRejected),
        (TCStatus.deviceUnavailable, TunnelEngineError.socketsUnavailable),
        (TCStatus.internalFailure, TunnelEngineError.internalFailure),
    ])
    func mapsEveryFailureStatusToADomainError(status: TCStatus, error: TunnelEngineError) {
        #expect(TunnelEngineError(status: status) == error)
    }

    @Test
    func treatsSuccessAsNoError() {
        #expect(TunnelEngineError(status: .OK) == nil)
    }
}
