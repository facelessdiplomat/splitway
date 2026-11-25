#if os(iOS)
    import ControlWidgets
    import ControlWidgetsInfrastructure
    import TunnelConnectionInfrastructure

    extension AppComposition {
        static func refreshingControls(connection: TunnelConnectionAssembly) -> Task<Void, Never> {
            let refresh = RefreshTunnelControlUseCase(
                observeConnection: connection.observeConnection,
                refresher: ControlCenterTunnelControlRefresher()
            )
            return Task { await refresh.execute() }
        }
    }
#endif
