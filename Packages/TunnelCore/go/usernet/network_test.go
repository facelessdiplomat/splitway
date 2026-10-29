package usernet

import (
	"bytes"
	"context"
	"errors"
	"net/netip"
	"slices"
	"sync"
	"testing"
	"time"

	"go.uber.org/goleak"
)

const (
	streamReadByteCount   = 64 * 1024
	datagramReadByteCount = 65535
	generousCredit        = 1 << 20
)

var streamOptions = ReceiveOptions{ReadByteCount: streamReadByteCount, InitialCredit: generousCredit}

func TestMain(m *testing.M) {
	goleak.VerifyTestMain(m)
}

func TestCarriesTCPThroughTheTunnelBothWays(t *testing.T) {
	pair := startTestPair(t)
	connection, receiver := dialReceiving(t, pair.client, echoPort, streamOptions)

	if _, err := connection.Write([]byte("hello through the tunnel")); err != nil {
		t.Fatal(err)
	}

	if received := receiver.waitForBytes(t, 24); string(received) != "hello through the tunnel" {
		t.Fatalf("echo differs: %q", received)
	}
}

func TestDeliversTheEchoAndTheEndOfStreamAfterHalfClose(t *testing.T) {
	pair := startTestPair(t)
	connection, receiver := dialReceiving(t, pair.client, echoPort, streamOptions)
	payload := bytes.Repeat([]byte("splitway"), 4096)

	if _, err := connection.Write(payload); err != nil {
		t.Fatal(err)
	}
	if err := connection.CloseWrite(); err != nil {
		t.Fatal(err)
	}

	if received := receiver.waitForBytes(t, len(payload)); !bytes.Equal(received, payload) {
		t.Fatal("echo differs from the payload")
	}
	if err := receiver.waitForFinish(t); err != nil {
		t.Fatalf("expected an orderly end of stream, got %v", err)
	}
}

func TestCarriesUDPDatagramsThroughTheTunnelBothWays(t *testing.T) {
	pair := startTestPair(t)
	connection, err := pair.client.DialUDP(netip.AddrPortFrom(serverAddress, echoPort))
	if err != nil {
		t.Fatal(err)
	}
	receiver := newRecordingReceiver(connection, true)
	connection.StartReceiving(receiver, ReceiveOptions{ReadByteCount: datagramReadByteCount, InitialCredit: generousCredit})

	if _, err := connection.Write([]byte("datagram")); err != nil {
		t.Fatal(err)
	}

	if datagram := receiver.waitForDatagram(t); string(datagram) != "datagram" {
		t.Fatalf("echoed datagram differs: %q", datagram)
	}
}

func TestResolvesNamesThroughTheTunnelDNS(t *testing.T) {
	pair := startTestPair(t)
	lookupContext, cancel := context.WithTimeout(context.Background(), deliveryTimeout)
	defer cancel()

	addresses, err := pair.client.LookupHost(lookupContext, tunnelHostname)

	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(addresses, []netip.Addr{serverAddress}) {
		t.Fatalf("resolved %v", addresses)
	}
}

func TestGivesUpDialingWhenTheTimeoutExpires(t *testing.T) {
	pair := startTestPair(t)
	dialContext, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()

	_, err := pair.client.DialTCP(dialContext, netip.AddrPortFrom(netip.MustParseAddr("10.0.0.3"), echoPort))

	if !isExpectedDialFailure(err) || !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("expected the dial to time out, got %v", err)
	}
}

func TestReportsARefusedConnection(t *testing.T) {
	pair := startTestPair(t)
	dialContext, cancel := context.WithTimeout(context.Background(), deliveryTimeout)
	defer cancel()

	_, err := pair.client.DialTCP(dialContext, netip.AddrPortFrom(serverAddress, closedPort))

	if !isExpectedDialFailure(err) {
		t.Fatalf("expected a refused connection, got %v", err)
	}
}

func TestClosingDuringAWriteStopsTheWriteAndTheReceiver(t *testing.T) {
	pair := startTestPair(t)
	connection, receiver := dialReceiving(t, pair.client, echoPort, ReceiveOptions{ReadByteCount: 1024, InitialCredit: 1})
	writeFinished := make(chan error, 1)

	go func() {
		chunk := make([]byte, 64*1024)
		for {
			if _, err := connection.Write(chunk); err != nil {
				writeFinished <- err
				return
			}
		}
	}()
	receiver.waitForBytes(t, 1)
	connection.Close()

	select {
	case err := <-writeFinished:
		if err == nil {
			t.Fatal("write succeeded after close")
		}
	case <-time.After(deliveryTimeout):
		t.Fatal("write did not stop after close")
	}
	if err := receiver.waitForFinish(t); err != nil {
		t.Fatalf("expected a local close to finish receiving quietly, got %v", err)
	}
}

func TestResumesReceivingWhenCreditIsGranted(t *testing.T) {
	pair := startTestPair(t)
	connection, receiver := dialReceiving(t, pair.client, echoPort, ReceiveOptions{ReadByteCount: 4, InitialCredit: 4})

	if _, err := connection.Write([]byte("abcdefgh")); err != nil {
		t.Fatal(err)
	}
	first := receiver.waitForBytes(t, 4)
	connection.Grant(4)

	if received := receiver.waitForBytes(t, 8); string(first) != "abcd" || string(received) != "abcdefgh" {
		t.Fatalf("received %q then %q", first, received)
	}
}

func TestCarriesAThousandParallelConnections(t *testing.T) {
	pair := startTestPair(t)
	var group sync.WaitGroup
	failures := make(chan error, 1000)

	for index := range 1000 {
		group.Add(1)
		go func() {
			defer group.Done()
			failures <- roundTrip(pair.client, []byte{byte(index), byte(index >> 8), 'o', 'k'})
		}()
	}
	group.Wait()
	close(failures)

	for err := range failures {
		if err != nil {
			t.Fatal(err)
		}
	}
}

func TestStopClosesEveryConnectionAndRefusesNewOnes(t *testing.T) {
	pair := startTestPair(t)
	receivers := make([]*recordingReceiver, 0, 3)
	for range 3 {
		_, receiver := dialReceiving(t, pair.client, echoPort, streamOptions)
		receivers = append(receivers, receiver)
	}

	pair.client.Stop()

	for _, receiver := range receivers {
		if err := receiver.waitForFinish(t); err != nil {
			t.Fatalf("expected stop to finish receiving quietly, got %v", err)
		}
	}
	_, err := pair.client.DialTCP(context.Background(), netip.AddrPortFrom(serverAddress, echoPort))
	if !errors.Is(err, ErrNetworkStopped) {
		t.Fatalf("expected a stopped network, got %v", err)
	}
}

func BenchmarkUploadThroughTheTunnel(b *testing.B) {
	pair := startTestPair(b)
	dialContext, cancel := context.WithTimeout(context.Background(), deliveryTimeout)
	defer cancel()
	connection, err := pair.client.DialTCP(dialContext, netip.AddrPortFrom(serverAddress, discardPort))
	if err != nil {
		b.Fatal(err)
	}
	defer connection.Close()
	chunk := make([]byte, streamReadByteCount)
	b.SetBytes(int64(len(chunk)))

	for b.Loop() {
		if _, err := connection.Write(chunk); err != nil {
			b.Fatal(err)
		}
	}
}

func dialReceiving(t testing.TB, network *Network, port uint16, options ReceiveOptions) (*Connection, *recordingReceiver) {
	t.Helper()
	dialContext, cancel := context.WithTimeout(context.Background(), deliveryTimeout)
	defer cancel()
	connection, err := network.DialTCP(dialContext, netip.AddrPortFrom(serverAddress, port))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { connection.Close() })
	receiver := newRecordingReceiver(connection, options.InitialCredit == generousCredit)
	connection.StartReceiving(receiver, options)
	return connection, receiver
}

func roundTrip(network *Network, message []byte) error {
	roundTripContext, cancel := context.WithTimeout(context.Background(), deliveryTimeout)
	defer cancel()
	connection, err := network.DialTCP(roundTripContext, netip.AddrPortFrom(serverAddress, echoPort))
	if err != nil {
		return err
	}
	defer connection.Close()
	receiver := newRecordingReceiver(connection, true)
	connection.StartReceiving(receiver, streamOptions)
	if _, err := connection.Write(message); err != nil {
		return err
	}
	select {
	case <-receiver.arrived:
	case <-roundTripContext.Done():
		return roundTripContext.Err()
	}
	return nil
}
