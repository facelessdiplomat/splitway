import PacketTunnel
import Testing
import TunnelEngine

@Suite
struct PacketTunnelSessionTests {
    @Test
    func resolvesAppliesSettingsLocatesTheInterfaceAndStartsTheDeviceInOrder() async throws {
        let environment = try SessionTestEnvironment()

        try await environment.start()

        #expect(
            environment.log.events == [
                .resolved(SessionTestEnvironment.endpoint), .appliedSettings, .locatedInterface,
                .startedDevice(descriptor: 7),
            ]
        )
        #expect(environment.device.receivedConfigurations.last?.text.contains("endpoint=203.0.113.5:51820\n") == true)
    }

    @Test
    func reResolvesEndpointsAndRebindsSocketsWhenTheNetworkPathReturns() async throws {
        let environment = try SessionTestEnvironment()
        try await environment.start()
        environment.resolver.answer(
            SessionTestEnvironment.endpoint, with: try SessionTestEnvironment.resolvedEndpoint("64:ff9b::cb00:7105"))
        environment.log.removeAll()

        await environment.session.handle(.available)

        #expect(
            environment.log.events == [
                .resolved(SessionTestEnvironment.endpoint), .appliedConfiguration, .bumpedSockets,
            ])
        #expect(
            environment.device.receivedConfigurations.last?.text.contains("endpoint=[64:ff9b::cb00:7105]:51820\n")
                == true
        )
    }

    @Test
    func waitsForTheNetworkWhenThePathIsLost() async throws {
        let environment = try SessionTestEnvironment()
        try await environment.start()
        environment.log.removeAll()

        await environment.session.handle(.unavailable)

        #expect(environment.log.events.isEmpty)
    }

    @Test
    func abandonsAStartThatWasStoppedMidwayWithoutStartingTheDevice() async throws {
        let environment = try SessionTestEnvironment()
        await environment.resolver.gate.holdNextResolution()

        let start = Task { try await environment.start() }
        await environment.resolver.gate.waitUntilResolutionIsHeld()
        await environment.session.stop()
        await environment.resolver.gate.releaseHeldResolution()

        await #expect(throws: PacketTunnelError.cancelled) {
            try await start.value
        }
        #expect(environment.log.events == [.resolved(SessionTestEnvironment.endpoint)])
    }

    @Test
    func reportsAnUnresolvableEndpointBeforeTouchingTheNetwork() async throws {
        let environment = try SessionTestEnvironment()
        environment.resolver.answer(
            "unrelated.example.com:51820", with: try SessionTestEnvironment.resolvedEndpoint("203.0.113.9"))
        let session = environment.session
        let configuration = try SessionTestEnvironmentWithoutAnswers.configuration()

        await #expect(throws: PacketTunnelError.endpointUnresolvable) {
            try await session.start(configuration: configuration, routedBy: .default)
        }
        #expect(environment.log.events.isEmpty)
    }

    @Test
    func reportsRejectedNetworkSettingsWithoutStartingTheDevice() async throws {
        let environment = try SessionTestEnvironment(rejectsSettings: true)

        await #expect(throws: PacketTunnelError.networkSettingsRejected) {
            try await environment.start()
        }
        #expect(environment.log.events == [.resolved(SessionTestEnvironment.endpoint)])
    }

    @Test
    func reportsAMissingTunnelInterface() async throws {
        let environment = try SessionTestEnvironment(tunnelDescriptor: nil)

        await #expect(throws: PacketTunnelError.tunnelInterfaceUnavailable) {
            try await environment.start()
        }
    }

    @Test
    func reportsTheEngineFailure() async throws {
        let environment = try SessionTestEnvironment(engineFailure: .configurationRejected)

        await #expect(throws: PacketTunnelError.engineFailed(.configurationRejected)) {
            try await environment.start()
        }
    }

    @Test
    func rebindsSocketsAfterWakingUp() async throws {
        let environment = try SessionTestEnvironment()
        try await environment.start()
        environment.log.removeAll()

        await environment.session.wake()

        #expect(environment.log.events == [.bumpedSockets])
    }

    @Test
    func stopsTheRunningDevice() async throws {
        let environment = try SessionTestEnvironment()
        try await environment.start()

        await environment.session.stop()

        #expect(environment.log.events.last == .stoppedDevice)
        await #expect(throws: PacketTunnelError.notRunning) {
            try await environment.session.runtimeStatistics()
        }
    }

    @Test
    func reportsTheStatisticsOfTheRunningDevice() async throws {
        let environment = try SessionTestEnvironment()
        try await environment.start()

        #expect(try await environment.session.runtimeStatistics() == RuntimeStatistics(peers: []))
    }
}
