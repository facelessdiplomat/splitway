import TunnelImport

struct FakeCameraAccess: CameraAccess {
    let current: CameraAuthorization
    let grantsAccess: Bool

    init(_ current: CameraAuthorization, grantsAccess: Bool = false) {
        self.current = current
        self.grantsAccess = grantsAccess
    }

    func authorization() -> CameraAuthorization {
        current
    }

    func requestAccess() async -> Bool {
        grantsAccess
    }
}
