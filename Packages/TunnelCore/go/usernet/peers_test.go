package usernet

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net"
	"net/netip"
	"strconv"
	"strings"
	"testing"

	"golang.org/x/crypto/curve25519"
	"golang.org/x/net/dns/dnsmessage"
	"golang.zx2c4.com/wireguard/device"
)

const (
	echoPort       = 7
	discardPort    = 9
	closedPort     = 19
	dnsPort        = 53
	testMTU        = 1420
	tunnelHostname = "echo.tunnel.test."
)

var (
	clientAddress = netip.MustParseAddr("10.0.0.1")
	serverAddress = netip.MustParseAddr("10.0.0.2")
)

type testPair struct {
	client *Network
	server *Network
}

func startTestPair(t testing.TB) *testPair {
	t.Helper()
	clientKey, serverKey := randomPrivateKey(t), randomPrivateKey(t)
	client := startTestNetwork(t, clientKey, clientAddress, []netip.Addr{serverAddress})
	server := startTestNetwork(t, serverKey, serverAddress, nil)
	connect(t, client, serverKey, serverAddress, listenPort(t, server))
	connect(t, server, clientKey, clientAddress, listenPort(t, client))
	serveTCP(t, server, echoPort, echo)
	serveTCP(t, server, discardPort, discard)
	serveUDPEcho(t, server)
	serveDNS(t, server)
	return &testPair{client: client, server: server}
}

func startTestNetwork(t testing.TB, privateKey [32]byte, address netip.Addr, dnsServers []netip.Addr) *Network {
	t.Helper()
	options := Options{Addresses: []netip.Addr{address}, DNSServers: dnsServers, MTU: testMTU}
	configuration := "private_key=" + hex.EncodeToString(privateKey[:]) + "\nlisten_port=0\n"
	network, err := Start(options, configuration, device.NewLogger(device.LogLevelSilent, ""))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(network.Stop)
	return network
}

func connect(t testing.TB, network *Network, peerPrivateKey [32]byte, peerAddress netip.Addr, peerPort int) {
	t.Helper()
	peerPublicKey, err := curve25519.X25519(peerPrivateKey[:], curve25519.Basepoint)
	if err != nil {
		t.Fatal(err)
	}
	configuration := strings.Join([]string{
		"replace_peers=true",
		"public_key=" + hex.EncodeToString(peerPublicKey),
		fmt.Sprintf("endpoint=127.0.0.1:%d", peerPort),
		"replace_allowed_ips=true",
		"allowed_ip=" + netip.PrefixFrom(peerAddress, peerAddress.BitLen()).String(),
	}, "\n") + "\n"
	if err := network.Apply(configuration); err != nil {
		t.Fatal(err)
	}
}

func listenPort(t testing.TB, network *Network) int {
	t.Helper()
	configuration, err := network.Configuration()
	if err != nil {
		t.Fatal(err)
	}
	for _, line := range strings.Split(configuration, "\n") {
		if value, found := strings.CutPrefix(line, "listen_port="); found {
			port, err := strconv.Atoi(value)
			if err != nil {
				t.Fatal(err)
			}
			return port
		}
	}
	t.Fatal("running network reported no listen port")
	return 0
}

func serveTCP(t testing.TB, server *Network, port uint16, handle func(net.Conn)) {
	t.Helper()
	listener, err := server.stack.ListenTCPAddrPort(netip.AddrPortFrom(serverAddress, port))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { listener.Close() })
	go func() {
		for {
			connection, err := listener.Accept()
			if err != nil {
				return
			}
			go handle(connection)
		}
	}()
}

func echo(connection net.Conn) {
	defer connection.Close()
	if _, err := io.Copy(connection, connection); err != nil {
		return
	}
	if halves, ok := connection.(interface{ CloseWrite() error }); ok {
		halves.CloseWrite()
	}
}

func discard(connection net.Conn) {
	defer connection.Close()
	io.Copy(io.Discard, connection)
}

func serveUDPEcho(t testing.TB, server *Network) {
	t.Helper()
	serveDatagrams(t, server, echoPort, func(datagram []byte) ([]byte, bool) { return datagram, true })
}

func serveDNS(t testing.TB, server *Network) {
	t.Helper()
	serveDatagrams(t, server, dnsPort, answerQuery)
}

func serveDatagrams(t testing.TB, server *Network, port uint16, respond func([]byte) ([]byte, bool)) {
	t.Helper()
	socket, err := server.stack.ListenUDPAddrPort(netip.AddrPortFrom(serverAddress, port))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { socket.Close() })
	go func() {
		buffer := make([]byte, 65535)
		for {
			byteCount, sender, err := socket.ReadFrom(buffer)
			if err != nil {
				return
			}
			if response, ok := respond(buffer[:byteCount]); ok {
				socket.WriteTo(response, sender)
			}
		}
	}()
}

func answerQuery(query []byte) ([]byte, bool) {
	var parser dnsmessage.Parser
	header, err := parser.Start(query)
	if err != nil {
		return nil, false
	}
	question, err := parser.Question()
	if err != nil {
		return nil, false
	}
	builder := dnsmessage.NewBuilder(nil, dnsmessage.Header{ID: header.ID, Response: true, RecursionAvailable: true})
	builder.StartQuestions()
	builder.Question(question)
	builder.StartAnswers()
	if question.Type == dnsmessage.TypeA && question.Name.String() == tunnelHostname {
		resource := dnsmessage.ResourceHeader{Name: question.Name, Class: dnsmessage.ClassINET, TTL: 60}
		builder.AResource(resource, dnsmessage.AResource{A: serverAddress.As4()})
	}
	response, err := builder.Finish()
	return response, err == nil
}

func randomPrivateKey(t testing.TB) [32]byte {
	t.Helper()
	var key [32]byte
	if _, err := rand.Read(key[:]); err != nil {
		t.Fatal(err)
	}
	key[0] &= 248
	key[31] = (key[31] & 127) | 64
	return key
}

func isExpectedDialFailure(err error) bool {
	return errors.Is(err, ErrDialFailed)
}
