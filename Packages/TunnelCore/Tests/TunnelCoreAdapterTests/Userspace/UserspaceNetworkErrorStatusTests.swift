import Testing
import TunnelCoreFramework
import TunnelEngine

@testable import TunnelCoreAdapter

@Suite
struct UserspaceNetworkErrorStatusTests {
    @Test(arguments: [
        (TCStatus.connectionFailed, UserspaceNetworkError.connectionFailed),
        (TCStatus.timedOut, UserspaceNetworkError.timedOut),
        (TCStatus.lookupFailed, UserspaceNetworkError.lookupFailed),
        (TCStatus.networkStopped, UserspaceNetworkError.networkStopped),
        (TCStatus.connectionClosed, UserspaceNetworkError.connectionClosed),
        (TCStatus.invalidArgument, UserspaceNetworkError.internalFailure),
        (TCStatus.tunnelInterfaceUnavailable, UserspaceNetworkError.internalFailure),
        (TCStatus.configurationRejected, UserspaceNetworkError.internalFailure),
        (TCStatus.deviceUnavailable, UserspaceNetworkError.internalFailure),
        (TCStatus.internalFailure, UserspaceNetworkError.internalFailure),
    ])
    func mapsEveryFailureStatusToANetworkError(status: TCStatus, error: UserspaceNetworkError) {
        #expect(UserspaceNetworkError(status: status, releasedHandle: .connectionClosed) == error)
    }

    @Test(arguments: [UserspaceNetworkError.networkStopped, UserspaceNetworkError.connectionClosed])
    func reportsAReleasedHandleAsTheErrorOfItsKind(releasedHandle: UserspaceNetworkError) {
        #expect(UserspaceNetworkError(status: .unknownHandle, releasedHandle: releasedHandle) == releasedHandle)
    }

    @Test
    func treatsSuccessAsNoError() {
        #expect(UserspaceNetworkError(status: .OK, releasedHandle: .connectionClosed) == nil)
    }

    @Test
    func finishesWithoutAnErrorOnlyAfterAnOrderlyEnd() {
        #expect(UserspaceNetworkError(finishing: .OK) == nil)
        #expect(UserspaceNetworkError(finishing: .connectionFailed) == .connectionFailed)
    }

    @Test
    func passesTimeoutsInWholeMillisecondsWithinTheCRange() {
        #expect(Duration.milliseconds(1_500).wholeMilliseconds == 1_500)
        #expect(Duration.seconds(0.0004).wholeMilliseconds == 0)
        #expect(Duration.seconds(Int64.max).wholeMilliseconds == Int32.max)
    }
}
