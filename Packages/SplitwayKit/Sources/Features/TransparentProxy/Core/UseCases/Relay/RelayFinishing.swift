import TunnelEngine

struct RelayFinishing: Sendable {
    let connections: [any UserspaceConnection]
    let onFinish: (@Sendable () -> Void)?

    func closeConnections() {
        for connection in connections {
            connection.close(.both)
        }
    }
}
