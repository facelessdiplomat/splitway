package usernet

import (
	"errors"
	"io"
	"net"
	"sync"
	"sync/atomic"
)

type Receiver interface {
	Receive(data []byte)
	Finish(err error)
}

type ReceiveOptions struct {
	ReadByteCount int
	InitialCredit int
}

type halfClosable interface {
	CloseRead() error
	CloseWrite() error
}

type Connection struct {
	stream    net.Conn
	window    *creditWindow
	registry  *connectionRegistry
	isClosed  atomic.Bool
	startOnce sync.Once
}

func newConnection(stream net.Conn, registry *connectionRegistry) *Connection {
	return &Connection{stream: stream, window: newCreditWindow(), registry: registry}
}

func (connection *Connection) StartReceiving(receiver Receiver, options ReceiveOptions) {
	connection.startOnce.Do(func() {
		connection.window.grant(options.InitialCredit)
		buffer := make([]byte, options.ReadByteCount)
		if !connection.registry.startReceiver(func() { connection.receive(receiver, buffer) }) {
			receiver.Finish(nil)
		}
	})
}

func (connection *Connection) Write(data []byte) (int, error) {
	return connection.stream.Write(data)
}

func (connection *Connection) Grant(byteCount int) {
	connection.window.grant(byteCount)
}

func (connection *Connection) CloseRead() error {
	halves, ok := connection.stream.(halfClosable)
	if !ok {
		return connection.Close()
	}
	connection.window.close()
	return halves.CloseRead()
}

func (connection *Connection) CloseWrite() error {
	if halves, ok := connection.stream.(halfClosable); ok {
		return halves.CloseWrite()
	}
	return nil
}

func (connection *Connection) Close() error {
	if !connection.isClosed.CompareAndSwap(false, true) {
		return nil
	}
	connection.window.close()
	err := connection.stream.Close()
	connection.registry.remove(connection)
	return err
}

func (connection *Connection) receive(receiver Receiver, buffer []byte) {
	for connection.window.awaitCredit() {
		byteCount, err := connection.stream.Read(buffer)
		if byteCount > 0 {
			connection.window.spend(byteCount)
			receiver.Receive(buffer[:byteCount])
		}
		if err != nil {
			receiver.Finish(connection.finishingError(err))
			return
		}
	}
	receiver.Finish(nil)
}

func (connection *Connection) finishingError(err error) error {
	if errors.Is(err, io.EOF) || connection.isClosed.Load() {
		return nil
	}
	return err
}
