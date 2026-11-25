//go:build !ios

package main

import (
	"bytes"
	"encoding/hex"
	"sync"
	"testing"
	"time"

	"golang.org/x/crypto/curve25519"
	"golang.zx2c4.com/wireguard/device"
	"golang.zx2c4.com/wireguard/tun/tuntest"
	"splitway/tunnelcore/fdtunnel"
	"splitway/tunnelcore/internal/testpeer"
)

const (
	bridgeDeliveryTimeout = 20 * time.Second
	shortDialTimeout      = 300
	longDialTimeout       = 20_000
	readByteCount         = 4096
	generousCredit        = 1 << 20
)

func TestOperatesAUserspaceNetworkThroughTheTunnelHandles(t *testing.T) {
	handle := startBridgeNetwork(t, testpeer.ServerAddress.String())

	if status := updateTunnelConfiguration(handle, "replace_peers=true\n"); status != statusOK {
		t.Fatalf("expected the update to succeed, got %d", status)
	}
	if _, status := tunnelConfiguration(handle); status != statusOK {
		t.Fatalf("expected the configuration, got %d", status)
	}
	if status := stopTunnel(handle); status != statusOK {
		t.Fatalf("expected the network to stop, got %d", status)
	}
}

func TestRejectsMalformedNetworkAddresses(t *testing.T) {
	configuration := "private_key=" + interfacePrivateKeyHex + "\n"

	if _, status := startUserspaceNetwork(configuration, "10.0.0.1\nnot-an-address", "", testpeer.MTU); status != statusInvalidArgument {
		t.Errorf("addresses: expected an invalid argument, got %d", status)
	}
	if _, status := startUserspaceNetwork(configuration, "10.0.0.1", "dns.example", testpeer.MTU); status != statusInvalidArgument {
		t.Errorf("DNS servers: expected an invalid argument, got %d", status)
	}
}

func TestCarriesAConnectionThroughTheBridge(t *testing.T) {
	network := startBridgePair(t)
	connection := dialBridgeTCP(t, network, testpeer.EchoPort)
	receiver := newBridgeReceiver()

	if status := startReceiving(connection, receiver, make([]byte, readByteCount), generousCredit); status != statusOK {
		t.Fatalf("expected receiving to start, got %d", status)
	}
	if written, status := writeToConnection(connection, []byte("bridged")); status != statusOK || written != 7 {
		t.Fatalf("expected the write to succeed, got %d after %d bytes", status, written)
	}
	if status := closeConnection(connection, closingWrite); status != statusOK {
		t.Fatalf("expected the write side to close, got %d", status)
	}

	if received, finishing := receiver.waitForFinish(t); string(received) != "bridged" || finishing != nil {
		t.Fatalf("received %q and finished with %v", received, finishing)
	}
	if status := closeConnection(connection, closingBoth); status != statusOK {
		t.Fatalf("expected the connection to close, got %d", status)
	}
	if status := closeConnection(connection, closingBoth); status != statusUnknownHandle {
		t.Fatalf("expected a released handle, got %d", status)
	}
}

func TestCarriesADatagramThroughTheBridge(t *testing.T) {
	network := startBridgePair(t)
	connection, status := dialUDP(network, testpeer.ServerAddress.String(), testpeer.EchoPort)
	if status != statusOK {
		t.Fatalf("expected the socket to open, got %d", status)
	}
	defer closeConnection(connection, closingBoth)
	receiver := newBridgeReceiver()
	startReceiving(connection, receiver, make([]byte, readByteCount), generousCredit)

	writeToConnection(connection, []byte("datagram"))

	if received := receiver.waitForBytes(t, 8); string(received) != "datagram" {
		t.Fatalf("received %q", received)
	}
}

func TestReportsRefusedAndTimedOutConnections(t *testing.T) {
	network := startBridgePair(t)

	if _, status := dialTCP(network, testpeer.ServerAddress.String(), testpeer.ClosedPort, longDialTimeout); status != statusConnectionFailed {
		t.Errorf("closed port: expected a failed connection, got %d", status)
	}
	if _, status := dialTCP(network, "10.0.0.3", testpeer.EchoPort, shortDialTimeout); status != statusTimedOut {
		t.Errorf("unanswered address: expected a timeout, got %d", status)
	}
}

func TestResolvesNamesThroughTheBridge(t *testing.T) {
	network := startBridgePair(t)

	addresses, status := lookupHost(network, testpeer.Hostname, longDialTimeout)

	if status != statusOK || addresses != testpeer.ServerAddress.String() {
		t.Fatalf("expected %s, got %q with %d", testpeer.ServerAddress, addresses, status)
	}
}

func TestStoppingTheNetworkFinishesItsConnections(t *testing.T) {
	network := startBridgePair(t)
	connection := dialBridgeTCP(t, network, testpeer.EchoPort)
	receiver := newBridgeReceiver()
	startReceiving(connection, receiver, make([]byte, readByteCount), generousCredit)

	stopTunnel(network)

	if _, finishing := receiver.waitForFinish(t); finishing != nil {
		t.Fatalf("expected a quiet finish, got %v", finishing)
	}
	if _, status := writeToConnection(connection, []byte("late")); status != statusConnectionClosed {
		t.Fatalf("expected a closed connection, got %d", status)
	}
	closeConnection(connection, closingBoth)
}

func TestRejectsNetworkOperationsOnOtherHandles(t *testing.T) {
	tunnel, status := startTunnel(func(logger *device.Logger) (runningDevice, error) {
		return fdtunnel.Start(tuntest.NewChannelTUN().TUN(), "private_key="+interfacePrivateKeyHex+"\n", logger)
	})
	if status != statusOK {
		t.Fatalf("expected the tunnel to start, got %d", status)
	}
	defer stopTunnel(tunnel)

	if _, status := dialTCP(tunnel, testpeer.ServerAddress.String(), testpeer.EchoPort, shortDialTimeout); status != statusInvalidArgument {
		t.Errorf("file descriptor tunnel: expected an invalid argument, got %d", status)
	}
	if _, status := dialUDP(unknownHandle, testpeer.ServerAddress.String(), testpeer.EchoPort); status != statusUnknownHandle {
		t.Errorf("unknown network: expected an unknown handle, got %d", status)
	}
	if _, status := writeToConnection(unknownHandle, []byte("x")); status != statusUnknownHandle {
		t.Errorf("unknown connection: expected an unknown handle, got %d", status)
	}
	if status := grantCredit(unknownHandle, 1); status != statusUnknownHandle {
		t.Errorf("unknown connection grant: expected an unknown handle, got %d", status)
	}
}

func TestRejectsServiceRoutingOnAUserspaceNetwork(t *testing.T) {
	network := startBridgeNetwork(t, testpeer.ServerAddress.String())

	if status := setServiceRouting(network, planFixture(t)); status != statusInvalidArgument {
		t.Fatalf("expected an invalid argument, got %d", status)
	}
}

func TestTurnsAPanicIntoAnInternalFailure(t *testing.T) {
	status := guarded(func() tunnelStatus { panic("unexpected") })

	if status != statusInternalFailure {
		t.Fatalf("expected an internal failure, got %d", status)
	}
}

func startBridgeNetwork(t *testing.T, dnsServers string) int32 {
	t.Helper()
	clientKey, err := testpeer.RandomPrivateKey()
	if err != nil {
		t.Fatal(err)
	}
	configuration := "private_key=" + hex.EncodeToString(clientKey[:]) + "\nlisten_port=0\n"
	handle, status := startUserspaceNetwork(configuration, testpeer.ClientAddress.String(), dnsServers, testpeer.MTU)
	if status != statusOK {
		t.Fatalf("expected the network to start, got %d", status)
	}
	t.Cleanup(func() { stopTunnel(handle) })
	return handle
}

func startBridgePair(t *testing.T) int32 {
	t.Helper()
	clientKey, err := testpeer.RandomPrivateKey()
	if err != nil {
		t.Fatal(err)
	}
	clientPublicKey, err := curve25519.X25519(clientKey[:], curve25519.Basepoint)
	if err != nil {
		t.Fatal(err)
	}
	peer, err := testpeer.Start([32]byte(clientPublicKey), device.NewLogger(device.LogLevelSilent, ""))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(peer.Stop)
	configuration := "private_key=" + hex.EncodeToString(clientKey[:]) + "\nlisten_port=0\n"
	handle, status := startUserspaceNetwork(configuration, testpeer.ClientAddress.String(), testpeer.ServerAddress.String(), testpeer.MTU)
	if status != statusOK {
		t.Fatalf("expected the network to start, got %d", status)
	}
	t.Cleanup(func() { stopTunnel(handle) })
	if status := updateTunnelConfiguration(handle, testpeer.ClientPeerConfiguration(peer)); status != statusOK {
		t.Fatalf("expected the peer to apply, got %d", status)
	}
	return handle
}

func dialBridgeTCP(t *testing.T, network int32, port uint16) int32 {
	t.Helper()
	connection, status := dialTCP(network, testpeer.ServerAddress.String(), port, longDialTimeout)
	if status != statusOK {
		t.Fatalf("expected the connection to open, got %d", status)
	}
	return connection
}

type bridgeReceiver struct {
	mutex    sync.Mutex
	received bytes.Buffer
	arrived  chan struct{}
	finished chan error
}

func newBridgeReceiver() *bridgeReceiver {
	return &bridgeReceiver{arrived: make(chan struct{}, 1), finished: make(chan error, 1)}
}

func (receiver *bridgeReceiver) Receive(data []byte) {
	receiver.mutex.Lock()
	receiver.received.Write(data)
	receiver.mutex.Unlock()
	select {
	case receiver.arrived <- struct{}{}:
	default:
	}
}

func (receiver *bridgeReceiver) Finish(err error) {
	receiver.finished <- err
}

func (receiver *bridgeReceiver) snapshot() []byte {
	receiver.mutex.Lock()
	defer receiver.mutex.Unlock()
	return bytes.Clone(receiver.received.Bytes())
}

func (receiver *bridgeReceiver) waitForBytes(t *testing.T, byteCount int) []byte {
	t.Helper()
	deadline := time.After(bridgeDeliveryTimeout)
	for {
		if received := receiver.snapshot(); len(received) >= byteCount {
			return received
		}
		select {
		case <-receiver.arrived:
		case <-deadline:
			t.Fatalf("received %q", receiver.snapshot())
		}
	}
}

func (receiver *bridgeReceiver) waitForFinish(t *testing.T) ([]byte, error) {
	t.Helper()
	select {
	case finishing := <-receiver.finished:
		return receiver.snapshot(), finishing
	case <-time.After(bridgeDeliveryTimeout):
		t.Fatal("receiving did not finish")
		return nil, nil
	}
}
