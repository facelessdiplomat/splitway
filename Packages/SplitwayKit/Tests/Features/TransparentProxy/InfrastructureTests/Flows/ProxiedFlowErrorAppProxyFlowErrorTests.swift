#if os(macOS)
    import Foundation
    import NetworkExtension
    import Testing
    import TransparentProxy
    import TransparentProxyInfrastructure

    @Suite
    struct ProxiedFlowErrorAppProxyFlowErrorTests {
        @Test(arguments: [
            (NEAppProxyFlowError.Code.refused, ProxiedFlowError.refused),
            (NEAppProxyFlowError.Code.timedOut, ProxiedFlowError.timedOut),
            (NEAppProxyFlowError.Code.peerReset, ProxiedFlowError.peerReset),
            (NEAppProxyFlowError.Code.aborted, ProxiedFlowError.aborted),
            (NEAppProxyFlowError.Code.internal, ProxiedFlowError.aborted),
            (NEAppProxyFlowError.Code.notConnected, ProxiedFlowError.aborted),
        ])
        func readsAFlowErrorOfTheSystem(code: NEAppProxyFlowError.Code, error: ProxiedFlowError) {
            #expect(ProxiedFlowError(appProxyError: NEAppProxyFlowError(code)) == error)
        }

        @Test
        func treatsAnyOtherErrorAsAnAbort() {
            #expect(ProxiedFlowError(appProxyError: CocoaError(.fileNoSuchFile)) == .aborted)
        }

        @Test(arguments: [ProxiedFlowError.refused, .timedOut, .peerReset, .aborted])
        func closesTheSystemFlowWithTheMatchingError(error: ProxiedFlowError) {
            #expect(ProxiedFlowError(appProxyError: error.appProxyError) == error)
        }
    }
#endif
