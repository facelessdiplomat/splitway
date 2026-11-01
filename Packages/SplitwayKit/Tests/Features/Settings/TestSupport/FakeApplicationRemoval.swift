import Settings
import Synchronization

public final class FakeApplicationRemoval: ApplicationRemoval {
    private let requests = Mutex<[String]>([])
    private let refusesTrash: Bool

    public init(refusesTrash: Bool = false) {
        self.refusesTrash = refusesTrash
    }

    public var performedRequests: [String] {
        requests.withLock { requests in requests }
    }

    public func moveToTrashAndQuit() async throws(ApplicationRemovalError) {
        guard !refusesTrash else { throw .notMovedToTrash }
        requests.withLock { requests in requests.append("trash") }
    }

    public func quit() async {
        requests.withLock { requests in requests.append("quit") }
    }
}
