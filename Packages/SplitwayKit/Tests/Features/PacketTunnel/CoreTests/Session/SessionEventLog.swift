import Synchronization

final class SessionEventLog: Sendable {
    enum Event: Equatable {
        case resolved(String)
        case appliedSettings
        case locatedInterface
        case startedDevice(descriptor: Int32)
        case appliedConfiguration
        case appliedServiceRouting
        case bumpedSockets
        case stoppedDevice
    }

    private let storage = Mutex<[Event]>([])

    var events: [Event] {
        storage.withLock { events in events }
    }

    func record(_ event: Event) {
        storage.withLock { events in events.append(event) }
    }

    func removeAll() {
        storage.withLock { events in events.removeAll() }
    }
}
