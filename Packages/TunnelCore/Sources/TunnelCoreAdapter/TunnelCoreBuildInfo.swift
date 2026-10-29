import TunnelCoreFramework

public enum TunnelCoreBuildInfo {
    public static var version: String {
        let versionPointer = tc_version()
        defer { tc_free(versionPointer) }
        return String(cString: versionPointer)
    }
}
