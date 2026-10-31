package usernet

import (
	"bytes"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

const deliveryTimeout = 20 * time.Second

type recordingReceiver struct {
	connection   *Connection
	grantsCredit bool
	mutex        sync.Mutex
	received     bytes.Buffer
	datagrams    [][]byte
	arrived      chan struct{}
	finished     chan error
}

func newRecordingReceiver(connection *Connection, grantsCredit bool) *recordingReceiver {
	return &recordingReceiver{
		connection:   connection,
		grantsCredit: grantsCredit,
		arrived:      make(chan struct{}, 1),
		finished:     make(chan error, 1),
	}
}

func (receiver *recordingReceiver) Receive(data []byte) {
	receiver.mutex.Lock()
	receiver.received.Write(data)
	receiver.datagrams = append(receiver.datagrams, bytes.Clone(data))
	receiver.mutex.Unlock()
	if receiver.grantsCredit {
		receiver.connection.Grant(len(data))
	}
	select {
	case receiver.arrived <- struct{}{}:
	default:
	}
}

func (receiver *recordingReceiver) Finish(err error) {
	receiver.finished <- err
}

func (receiver *recordingReceiver) waitForBytes(t testing.TB, byteCount int) []byte {
	t.Helper()
	deadline := time.After(deliveryTimeout)
	for {
		receiver.mutex.Lock()
		received := bytes.Clone(receiver.received.Bytes())
		receiver.mutex.Unlock()
		if len(received) >= byteCount {
			return received
		}
		select {
		case <-receiver.arrived:
		case <-deadline:
			t.Fatalf("received %d of %d bytes", len(received), byteCount)
		}
	}
}

func (receiver *recordingReceiver) waitForDatagram(t testing.TB) []byte {
	t.Helper()
	receiver.waitForBytes(t, 1)
	receiver.mutex.Lock()
	defer receiver.mutex.Unlock()
	return receiver.datagrams[0]
}

func (receiver *recordingReceiver) waitForFinish(t testing.TB) error {
	t.Helper()
	select {
	case err := <-receiver.finished:
		return err
	case <-time.After(deliveryTimeout):
		t.Fatal("receiving did not finish")
		return nil
	}
}

type countingReceiver struct {
	connection *Connection
	received   atomic.Int64
	arrived    chan struct{}
}

func newCountingReceiver(connection *Connection) *countingReceiver {
	return &countingReceiver{connection: connection, arrived: make(chan struct{}, 1)}
}

func (receiver *countingReceiver) Receive(data []byte) {
	receiver.received.Add(int64(len(data)))
	receiver.connection.Grant(len(data))
	select {
	case receiver.arrived <- struct{}{}:
	default:
	}
}

func (receiver *countingReceiver) Finish(error) {}

func (receiver *countingReceiver) waitUntilReceived(t testing.TB, byteCount int64) {
	t.Helper()
	deadline := time.After(deliveryTimeout)
	for receiver.received.Load() < byteCount {
		select {
		case <-receiver.arrived:
		case <-deadline:
			t.Fatalf("received %d of %d bytes", receiver.received.Load(), byteCount)
		}
	}
}
