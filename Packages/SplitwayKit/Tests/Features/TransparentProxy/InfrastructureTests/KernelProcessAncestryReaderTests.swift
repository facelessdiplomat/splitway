#if os(macOS)
    import Darwin
    import Testing
    import TransparentProxy
    import TransparentProxyInfrastructure

    @Suite
    struct KernelProcessAncestryReaderTests {
        @Test
        func findsTheProcessThatLaunchedThisOne() throws {
            let launcher = try #require(KernelProcessAncestryReader().launcher(of: getpid()))

            #expect(launcher.identifier == getppid())
            #expect(launcher.startTime > 0)
        }

        @Test
        func readsTheCodeIdentityOfTheLaunchingProcess() throws {
            let reader = KernelProcessAncestryReader()
            let launcher = try #require(reader.launcher(of: getpid()))

            let identity = try reader.codeIdentity(of: launcher)

            #expect(identity.executablePath != nil)
        }

        @Test
        func refusesAProcessThatStartedAtAnotherTime() throws {
            let reader = KernelProcessAncestryReader()
            let launcher = try #require(reader.launcher(of: getpid()))
            let impostor = RunningProcess(identifier: launcher.identifier, startTime: launcher.startTime + 1)

            #expect(throws: CodeIdentityReadingError.processUnavailable) {
                try reader.codeIdentity(of: impostor)
            }
        }

        @Test
        func findsNoLauncherOfAProcessThatDoesNotExist() {
            #expect(KernelProcessAncestryReader().launcher(of: Int32.max) == nil)
        }
    }
#endif
