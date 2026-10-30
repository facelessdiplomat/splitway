public protocol ApplicationFileReader: Sendable {
    func application(at path: String) async -> InstalledApplication?
}
