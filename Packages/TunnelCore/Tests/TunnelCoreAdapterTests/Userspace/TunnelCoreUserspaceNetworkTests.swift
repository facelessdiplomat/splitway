#if os(macOS)
    import SharedKernel
    import Testing
    import TunnelEngine

    @Suite(.timeLimit(.minutes(1)))
    struct TunnelCoreUserspaceNetworkTests {
        @Test
        func carriesTCPThroughTheTunnelBothWays() async throws {
            let fixture = try await UserspaceNetworkFixture.start()
            defer { fixture.stop() }
            let connection = try await fixture.dialTCP(port: UserspaceNetworkFixture.echoPort)
            let receiver = try fixture.receiving(connection)

            _ = try await fixture.write(Array("through the tunnel".utf8), to: connection)

            #expect(await receiver.bytes(count: 18) == Array("through the tunnel".utf8))
            connection.close(.both)
        }

        @Test
        func deliversTheEchoAndTheEndOfStreamAfterHalfClose() async throws {
            let fixture = try await UserspaceNetworkFixture.start()
            defer { fixture.stop() }
            let connection = try await fixture.dialTCP(port: UserspaceNetworkFixture.echoPort)
            let receiver = try fixture.receiving(connection)
            let payload = Array(repeating: UInt8(ascii: "s"), count: 32 * 1024)

            _ = try await fixture.write(payload, to: connection)
            connection.close(.write)

            let finish = try #require(await receiver.finishing())
            #expect(finish.bytes == payload)
            #expect(finish.error == nil)
            connection.close(.both)
        }

        @Test
        func carriesUDPDatagramsThroughTheTunnelBothWays() async throws {
            let fixture = try await UserspaceNetworkFixture.start()
            defer { fixture.stop() }
            let destination = try fixture.destination(port: UserspaceNetworkFixture.echoPort)
            let socket = try fixture.network.openUDP(to: destination)
            let receiver = try fixture.receiving(socket)

            _ = try await fixture.write(Array("datagram".utf8), to: socket)

            #expect(await receiver.bytes(count: 8) == Array("datagram".utf8))
            socket.close(.both)
        }

        @Test
        func reportsARefusedConnection() async throws {
            let fixture = try await UserspaceNetworkFixture.start()
            defer { fixture.stop() }

            await #expect(throws: UserspaceNetworkError.connectionFailed) {
                try await fixture.dialTCP(port: UserspaceNetworkFixture.closedPort)
            }
        }

        @Test
        func resolvesNamesThroughTheTunnelDNS() async throws {
            let fixture = try await UserspaceNetworkFixture.start()
            defer { fixture.stop() }
            let name = try DomainName(UserspaceNetworkFixture.hostname)
            let network = fixture.network

            let addresses = try await BlockingCall.perform { () throws(UserspaceNetworkError) in
                try network.lookUpAddresses(of: name, timeout: UserspaceNetworkFixture.dialTimeout)
            }

            #expect(addresses == [UserspaceNetworkFixture.serverAddress])
        }

        @Test
        func finishesConnectionsWhenTheNetworkStopsAndRefusesWritesAfterwards() async throws {
            let fixture = try await UserspaceNetworkFixture.start()
            defer { fixture.peer.stop() }
            let connection = try await fixture.dialTCP(port: UserspaceNetworkFixture.echoPort)
            let receiver = try fixture.receiving(connection)

            fixture.network.stop()

            let finish = try #require(await receiver.finishing())
            #expect(finish.error == nil)
            await #expect(throws: UserspaceNetworkError.connectionClosed) {
                try await fixture.write(Array("late".utf8), to: connection)
            }
            connection.close(.both)
        }
    }
#endif
