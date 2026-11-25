public protocol CameraAccess: Sendable {
    func authorization() -> CameraAuthorization
    func requestAccess() async -> Bool
}
