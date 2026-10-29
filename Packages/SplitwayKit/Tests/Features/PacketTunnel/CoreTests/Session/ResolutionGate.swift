actor ResolutionGate {
    private var isHoldingNextResolution = false
    private var heldResolution: CheckedContinuation<Void, Never>?
    private var holdWaiters: [CheckedContinuation<Void, Never>] = []

    func holdNextResolution() {
        isHoldingNextResolution = true
    }

    func passThrough() async {
        guard isHoldingNextResolution else { return }
        isHoldingNextResolution = false
        await withCheckedContinuation { continuation in
            heldResolution = continuation
            for waiter in holdWaiters {
                waiter.resume()
            }
            holdWaiters.removeAll()
        }
    }

    func waitUntilResolutionIsHeld() async {
        guard heldResolution == nil else { return }
        await withCheckedContinuation { continuation in holdWaiters.append(continuation) }
    }

    func releaseHeldResolution() {
        heldResolution?.resume()
        heldResolution = nil
    }
}
