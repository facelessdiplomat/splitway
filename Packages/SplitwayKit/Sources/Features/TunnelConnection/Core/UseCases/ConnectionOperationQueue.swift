actor ConnectionOperationQueue {
    private var isOperationRunning = false
    private var waitingOperations: [CheckedContinuation<Void, Never>] = []

    func enter() async {
        guard isOperationRunning else {
            isOperationRunning = true
            return
        }
        await withCheckedContinuation { continuation in waitingOperations.append(continuation) }
    }

    func leave() {
        guard !waitingOperations.isEmpty else {
            isOperationRunning = false
            return
        }
        waitingOperations.removeFirst().resume()
    }
}
