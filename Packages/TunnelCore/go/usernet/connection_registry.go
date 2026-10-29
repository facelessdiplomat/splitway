package usernet

import (
	"net"
	"sync"
)

type connectionRegistry struct {
	mutex       sync.Mutex
	connections map[*Connection]struct{}
	isStopped   bool
	receivers   sync.WaitGroup
}

func newConnectionRegistry() *connectionRegistry {
	return &connectionRegistry{connections: make(map[*Connection]struct{})}
}

func (registry *connectionRegistry) isAccepting() bool {
	registry.mutex.Lock()
	defer registry.mutex.Unlock()
	return !registry.isStopped
}

func (registry *connectionRegistry) add(stream net.Conn) (*Connection, error) {
	registry.mutex.Lock()
	defer registry.mutex.Unlock()
	if registry.isStopped {
		stream.Close()
		return nil, ErrNetworkStopped
	}
	connection := newConnection(stream, registry)
	registry.connections[connection] = struct{}{}
	return connection, nil
}

func (registry *connectionRegistry) remove(connection *Connection) {
	registry.mutex.Lock()
	defer registry.mutex.Unlock()
	delete(registry.connections, connection)
}

func (registry *connectionRegistry) startReceiver(receive func()) bool {
	registry.mutex.Lock()
	defer registry.mutex.Unlock()
	if registry.isStopped {
		return false
	}
	registry.receivers.Add(1)
	go func() {
		defer registry.receivers.Done()
		receive()
	}()
	return true
}

func (registry *connectionRegistry) closeAll() {
	registry.mutex.Lock()
	registry.isStopped = true
	connections := make([]*Connection, 0, len(registry.connections))
	for connection := range registry.connections {
		connections = append(connections, connection)
	}
	registry.mutex.Unlock()
	for _, connection := range connections {
		connection.Close()
	}
	registry.receivers.Wait()
}
