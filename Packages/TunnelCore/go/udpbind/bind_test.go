package udpbind

import (
	"bytes"
	"errors"
	"net"
	"net/netip"
	"syscall"
	"testing"
	"time"

	"go.uber.org/goleak"
	"golang.org/x/sys/unix"
	"golang.zx2c4.com/wireguard/conn"
)

const deliveryTimeout = 5 * time.Second

var (
	ipv4Loopback = netip.MustParseAddr("127.0.0.1")
	ipv6Loopback = netip.MustParseAddr("::1")
)

type loopbackCase struct {
	name     string
	network  string
	loopback netip.Addr
	receiver int
}

var loopbackCases = []loopbackCase{
	{name: "IPv4", network: "udp4", loopback: ipv4Loopback, receiver: 0},
	{name: "IPv6", network: "udp6", loopback: ipv6Loopback, receiver: 1},
}

func TestMain(m *testing.M) {
	goleak.VerifyTestMain(m)
}

func TestOpensBothAddressFamiliesOnTheSamePort(t *testing.T) {
	_, receivers, port := openBind(t, 0)

	if len(receivers) != 2 || port == 0 {
		t.Fatalf("expected two receivers on a chosen port, got %d receivers on port %d", len(receivers), port)
	}
}

func TestReceivesADatagramFromEitherAddressFamily(t *testing.T) {
	for _, test := range loopbackCases {
		t.Run(test.name, func(t *testing.T) {
			_, receivers, port := openBind(t, 0)
			client := listenOn(t, test.network, test.loopback)
			payload := []byte("handshake initiation")

			sendFrom(t, client, payload, netip.AddrPortFrom(test.loopback, port))
			datagram, sender := receiveOne(t, receivers[test.receiver])

			if !bytes.Equal(datagram, payload) {
				t.Fatalf("expected %q, got %q", payload, datagram)
			}
			if sender.DstToString() != client.LocalAddr().(*net.UDPAddr).AddrPort().String() {
				t.Fatalf("expected the client as sender, got %s", sender.DstToString())
			}
		})
	}
}

func TestReportsAnIPv4SenderWithoutAnIPv6Prefix(t *testing.T) {
	_, receivers, port := openBind(t, 0)
	client := listenOn(t, "udp4", ipv4Loopback)

	sendFrom(t, client, []byte("keepalive"), netip.AddrPortFrom(ipv4Loopback, port))
	_, sender := receiveOne(t, receivers[0])

	if !sender.DstIP().Is4() {
		t.Fatalf("expected an IPv4 sender, got %s", sender.DstIP())
	}
}

func TestSendsADatagramToEitherAddressFamily(t *testing.T) {
	for _, test := range loopbackCases {
		t.Run(test.name, func(t *testing.T) {
			bind, _, _ := openBind(t, 0)
			client := listenOn(t, test.network, test.loopback)
			endpoint := parse(t, bind, client.LocalAddr().(*net.UDPAddr).AddrPort().String())
			payload := []byte("transport data")

			err := bind.Send([][]byte{payload}, endpoint)

			if err != nil {
				t.Fatal(err)
			}
			expectDatagrams(t, client, payload)
		})
	}
}

func TestSendsEveryDatagramOfABatchInOrder(t *testing.T) {
	bind, _, _ := openBind(t, 0)
	client := listenOn(t, "udp4", ipv4Loopback)
	endpoint := parse(t, bind, client.LocalAddr().(*net.UDPAddr).AddrPort().String())
	batch := [][]byte{[]byte("first"), []byte("second"), []byte("third")}

	err := bind.Send(batch, endpoint)

	if err != nil {
		t.Fatal(err)
	}
	expectDatagrams(t, client, batch...)
}

func TestOpensTheRequestedPort(t *testing.T) {
	requested := freePort(t)

	_, _, port := openBind(t, requested)

	if port != requested {
		t.Fatalf("expected port %d, got %d", requested, port)
	}
}

func TestRefusesToOpenTwice(t *testing.T) {
	bind, _, _ := openBind(t, 0)

	_, _, err := bind.Open(0)

	if !errors.Is(err, conn.ErrBindAlreadyOpen) {
		t.Fatalf("expected ErrBindAlreadyOpen, got %v", err)
	}
}

func TestStopsReceivingOnceClosed(t *testing.T) {
	bind := New()
	receivers, _, err := bind.Open(0)
	if err != nil {
		t.Fatal(err)
	}

	closeErr := bind.Close()
	_, readErr := receivers[0]([][]byte{make([]byte, 1500)}, make([]int, 1), make([]conn.Endpoint, 1))

	if closeErr != nil {
		t.Fatal(closeErr)
	}
	if !errors.Is(readErr, net.ErrClosed) {
		t.Fatalf("expected net.ErrClosed, got %v", readErr)
	}
}

func TestOpensAgainAfterClose(t *testing.T) {
	bind := New()
	if _, _, err := bind.Open(0); err != nil {
		t.Fatal(err)
	}
	if err := bind.Close(); err != nil {
		t.Fatal(err)
	}

	receivers, port, err := bind.Open(0)
	t.Cleanup(func() { bind.Close() })

	if err != nil || len(receivers) != 2 || port == 0 {
		t.Fatalf("expected a reopened bind, got %d receivers on port %d and %v", len(receivers), port, err)
	}
}

func TestRefusesToSendWhileClosed(t *testing.T) {
	bind := New()
	endpoint := parse(t, bind, "127.0.0.1:51820")

	err := bind.Send([][]byte{[]byte("transport data")}, endpoint)

	if !errors.Is(err, syscall.EAFNOSUPPORT) {
		t.Fatalf("expected EAFNOSUPPORT, got %v", err)
	}
}

func TestRefusesAnEndpointOfAnotherBind(t *testing.T) {
	bind, _, _ := openBind(t, 0)
	foreign, err := conn.NewStdNetBind().ParseEndpoint("127.0.0.1:51820")
	if err != nil {
		t.Fatal(err)
	}

	sendErr := bind.Send([][]byte{[]byte("transport data")}, foreign)

	if !errors.Is(sendErr, conn.ErrWrongEndpointType) {
		t.Fatalf("expected ErrWrongEndpointType, got %v", sendErr)
	}
}

func TestParsesEndpoints(t *testing.T) {
	for _, test := range []struct {
		text        string
		destination string
		isValid     bool
	}{
		{text: "192.0.2.1:51820", destination: "192.0.2.1:51820", isValid: true},
		{text: "[2001:db8::1]:51820", destination: "[2001:db8::1]:51820", isValid: true},
		{text: "vpn.example.com:51820", isValid: false},
		{text: "192.0.2.1", isValid: false},
		{text: "", isValid: false},
	} {
		t.Run(test.text, func(t *testing.T) {
			endpoint, err := New().ParseEndpoint(test.text)

			if !test.isValid {
				if err == nil {
					t.Fatalf("expected %q to be rejected", test.text)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if endpoint.DstToString() != test.destination {
				t.Fatalf("expected %s, got %s", test.destination, endpoint.DstToString())
			}
		})
	}
}

func TestEncodesTheDestinationForCookies(t *testing.T) {
	destination := netip.MustParseAddrPort("[2001:db8::1]:51820")
	expected, err := destination.MarshalBinary()
	if err != nil {
		t.Fatal(err)
	}

	endpoint := parse(t, New(), destination.String())

	if !bytes.Equal(endpoint.DstToBytes(), expected) {
		t.Fatalf("expected %x, got %x", expected, endpoint.DstToBytes())
	}
}

func TestMovesOneDatagramPerCall(t *testing.T) {
	if size := New().BatchSize(); size != 1 {
		t.Fatalf("expected a batch size of 1, got %d", size)
	}
}

func TestEnlargesTheSocketBuffers(t *testing.T) {
	bind, _, _ := openBind(t, 0)

	for _, connection := range []*net.UDPConn{bind.ipv4, bind.ipv6} {
		receiveBuffer, sendBuffer := socketBuffers(t, connection)
		if receiveBuffer < socketBufferSize || sendBuffer < socketBufferSize {
			t.Fatalf("expected buffers of at least %d bytes, got %d and %d", socketBufferSize, receiveBuffer, sendBuffer)
		}
	}
}

func openBind(t *testing.T, port uint16) (*Bind, []conn.ReceiveFunc, uint16) {
	t.Helper()
	bind := New()
	receivers, openedPort, err := bind.Open(port)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { bind.Close() })
	return bind, receivers, openedPort
}

func listenOn(t *testing.T, network string, address netip.Addr) *net.UDPConn {
	t.Helper()
	connection, err := net.ListenUDP(network, net.UDPAddrFromAddrPort(netip.AddrPortFrom(address, 0)))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { connection.Close() })
	return connection
}

func sendFrom(t *testing.T, client *net.UDPConn, payload []byte, destination netip.AddrPort) {
	t.Helper()
	if _, err := client.WriteToUDPAddrPort(payload, destination); err != nil {
		t.Fatal(err)
	}
}

func receiveOne(t *testing.T, receive conn.ReceiveFunc) ([]byte, conn.Endpoint) {
	t.Helper()
	packets := [][]byte{make([]byte, 1500)}
	sizes := make([]int, 1)
	endpoints := make([]conn.Endpoint, 1)
	count, err := receive(packets, sizes, endpoints)
	if err != nil || count != 1 {
		t.Fatalf("expected one datagram, got %d and %v", count, err)
	}
	return packets[0][:sizes[0]], endpoints[0]
}

func expectDatagrams(t *testing.T, client *net.UDPConn, payloads ...[]byte) {
	t.Helper()
	if err := client.SetReadDeadline(time.Now().Add(deliveryTimeout)); err != nil {
		t.Fatal(err)
	}
	buffer := make([]byte, 1500)
	for _, payload := range payloads {
		size, _, err := client.ReadFromUDPAddrPort(buffer)
		if err != nil {
			t.Fatal(err)
		}
		if !bytes.Equal(buffer[:size], payload) {
			t.Fatalf("expected %q, got %q", payload, buffer[:size])
		}
	}
}

func parse(t *testing.T, bind *Bind, text string) conn.Endpoint {
	t.Helper()
	endpoint, err := bind.ParseEndpoint(text)
	if err != nil {
		t.Fatal(err)
	}
	return endpoint
}

func freePort(t *testing.T) uint16 {
	t.Helper()
	probe, err := net.ListenUDP("udp4", &net.UDPAddr{})
	if err != nil {
		t.Fatal(err)
	}
	port := probe.LocalAddr().(*net.UDPAddr).Port
	if err := probe.Close(); err != nil {
		t.Fatal(err)
	}
	return uint16(port)
}

func socketBuffers(t *testing.T, connection *net.UDPConn) (int, int) {
	t.Helper()
	raw, err := connection.SyscallConn()
	if err != nil {
		t.Fatal(err)
	}
	var receiveBuffer, sendBuffer int
	var optionErr error
	controlErr := raw.Control(func(descriptor uintptr) {
		receiveBuffer, optionErr = unix.GetsockoptInt(int(descriptor), unix.SOL_SOCKET, unix.SO_RCVBUF)
		if optionErr == nil {
			sendBuffer, optionErr = unix.GetsockoptInt(int(descriptor), unix.SOL_SOCKET, unix.SO_SNDBUF)
		}
	})
	if controlErr != nil || optionErr != nil {
		t.Fatalf("expected socket options, got %v and %v", controlErr, optionErr)
	}
	return receiveBuffer, sendBuffer
}
