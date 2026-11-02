import Settings
import Synchronization

public final class FakeApplicationRemoval: ApplicationRemoval {
    private let requests = Mutex<[String]>([])

    public init() {}

    public var performedRequests: [String] {
        requests.withLock { requests in requests }
    }

    public func showInFinderAndQuit() async {
        requests.withLock { requests in requests.append("show in Finder") }
    }

    public func quit() async {
        requests.withLock { requests in requests.append("quit") }
    }
}
