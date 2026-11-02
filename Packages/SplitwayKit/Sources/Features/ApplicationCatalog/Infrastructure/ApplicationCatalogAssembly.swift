#if os(macOS)
    import ApplicationCatalog

    public struct ApplicationCatalogAssembly: Sendable {
        private let scanner: FileSystemApplicationScanner
        private let signatures = SecurityCodeSignatureReader()
        public let iconLoader: WorkspaceIconLoader
        public let fileReader = FileSystemApplicationFileReader()
        public let fileAccess = SecurityScopedFileAccess()

        public init() {
            scanner = FileSystemApplicationScanner()
            iconLoader = WorkspaceIconLoader()
        }

        public var loadInstalledApplications: LoadInstalledApplicationsUseCase {
            LoadInstalledApplicationsUseCase(scanner: scanner)
        }

        public var resolveApplicationIdentity: ResolveApplicationIdentityUseCase {
            ResolveApplicationIdentityUseCase(signatures: signatures)
        }

        public var refreshSelectedApplications: RefreshSelectedApplicationsUseCase {
            RefreshSelectedApplicationsUseCase(resolve: resolveApplicationIdentity)
        }
    }
#endif
