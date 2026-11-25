import AppRouting

extension RoutingPlatform {
    public static var current: RoutingPlatform {
        #if os(macOS)
            .macOS
        #else
            .iOS
        #endif
    }
}
