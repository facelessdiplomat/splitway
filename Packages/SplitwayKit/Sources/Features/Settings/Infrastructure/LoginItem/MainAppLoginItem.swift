#if os(macOS)
    import ServiceManagement
    import Settings

    public struct MainAppLoginItem: LoginItem {
        public init() {}

        public func state() async -> LoginItemState {
            switch SMAppService.mainApp.status {
            case .enabled: .enabled
            case .requiresApproval: .requiresApproval
            default: .disabled
            }
        }

        public func enable() async throws(LoginItemError) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                throw .systemRefused
            }
        }

        public func disable() async throws(LoginItemError) {
            do {
                try await SMAppService.mainApp.unregister()
            } catch {
                throw .systemRefused
            }
        }

        public func openSystemSettings() async {
            await MainActor.run {
                SMAppService.openSystemSettingsLoginItems()
            }
        }
    }
#endif
