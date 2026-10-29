package fdtunnel

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"net/netip"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"go.uber.org/goleak"
	"golang.org/x/crypto/curve25519"
	"golang.zx2c4.com/wireguard/conn"
	"golang.zx2c4.com/wireguard/device"
	"golang.zx2c4.com/wireguard/tun/tuntest"
)

const packetDeliveryTimeout = 5 * time.Second

func TestMain(m *testing.M) {
	goleak.VerifyTestMain(m)
}

func TestTwoTunnelsHandshakeAndDeliverAPacket(t *testing.T) {
	first := startTestPeer(t, "10.0.0.1")
	second := startTestPeer(t, "10.0.0.2")
	first.connect(t, second)
	second.connect(t, first)

	ping := tuntest.Ping(second.address, first.address)
	first.channels.Outbound <- ping

	select {
	case delivered := <-second.channels.Inbound:
		if !bytes.Equal(delivered, ping) {
			t.Fatalf("delivered packet differs from the sent one")
		}
	case <-time.After(packetDeliveryTimeout):
		t.Fatal("packet was not delivered through the tunnel")
	}
	configuration, err := first.tunnel.Configuration()
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(configuration, "last_handshake_time_sec=0\n") {
		t.Fatal("handshake time was not recorded")
	}
}

func TestWireGuardAcceptsTheConfigurationEncodedBySplitway(t *testing.T) {
	fixture, err := os.ReadFile("testdata/full.uapi")
	if err != nil {
		t.Fatal(err)
	}
	wireGuardDevice := device.NewDevice(tuntest.NewChannelTUN().TUN(), conn.NewDefaultBind(), silentLogger())
	defer wireGuardDevice.Close()

	if err := wireGuardDevice.IpcSet(string(fixture)); err != nil {
		t.Fatalf("wireguard-go rejected the fixture: %v", err)
	}

	configuration, err := wireGuardDevice.IpcGet()
	if err != nil {
		t.Fatal(err)
	}
	for _, expected := range []string{
		"listen_port=51820\n",
		"public_key=de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f\n",
		"endpoint=[2001:db8::1]:51820\n",
		"persistent_keepalive_interval=25\n",
		"allowed_ip=0.0.0.0/0\n",
		"allowed_ip=::/0\n",
	} {
		if !strings.Contains(configuration, expected) {
			t.Errorf("applied configuration lacks %q", expected)
		}
	}
}

func TestRejectsAMalformedConfiguration(t *testing.T) {
	_, err := Start(tuntest.NewChannelTUN().TUN(), "private_key=zz\n", silentLogger())

	if !errors.Is(err, ErrConfigurationRejected) {
		t.Fatalf("expected a rejected configuration, got %v", err)
	}
}

func TestRejectsADescriptorThatIsNotATunnelInterface(t *testing.T) {
	file, err := os.Open(os.DevNull)
	if err != nil {
		t.Fatal(err)
	}
	defer file.Close()

	_, err = StartOnFileDescriptor(int(file.Fd()), privateKeyConfiguration(randomPrivateKey(t)), silentLogger())

	if !errors.Is(err, ErrTunnelInterfaceUnavailable) {
		t.Fatalf("expected an unavailable tunnel interface, got %v", err)
	}
}

func TestRejectsAClosedDescriptor(t *testing.T) {
	_, err := StartOnFileDescriptor(-1, privateKeyConfiguration(randomPrivateKey(t)), silentLogger())

	if !errors.Is(err, ErrTunnelInterfaceUnavailable) {
		t.Fatalf("expected an unavailable tunnel interface, got %v", err)
	}
}

func TestRebindsTheSocketsOfARunningTunnel(t *testing.T) {
	peer := startTestPeer(t, "10.0.0.1")

	if err := peer.tunnel.BumpSockets(); err != nil {
		t.Fatalf("expected sockets to rebind, got %v", err)
	}
}

type testPeer struct {
	channels  *tuntest.ChannelTUN
	tunnel    *Tunnel
	publicKey [32]byte
	address   netip.Addr
	port      int
}

func startTestPeer(t *testing.T, address string) *testPeer {
	t.Helper()
	privateKey := randomPrivateKey(t)
	publicKey, err := curve25519.X25519(privateKey[:], curve25519.Basepoint)
	if err != nil {
		t.Fatal(err)
	}
	channels := tuntest.NewChannelTUN()
	tunnel, err := Start(channels.TUN(), privateKeyConfiguration(privateKey)+"listen_port=0\n", silentLogger())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(tunnel.Stop)
	return &testPeer{
		channels:  channels,
		tunnel:    tunnel,
		publicKey: [32]byte(publicKey),
		address:   netip.MustParseAddr(address),
		port:      listenPort(t, tunnel),
	}
}

func (peer *testPeer) connect(t *testing.T, other *testPeer) {
	t.Helper()
	configuration := strings.Join([]string{
		"replace_peers=true",
		"public_key=" + hex.EncodeToString(other.publicKey[:]),
		fmt.Sprintf("endpoint=127.0.0.1:%d", other.port),
		"replace_allowed_ips=true",
		"allowed_ip=" + netip.PrefixFrom(other.address, other.address.BitLen()).String(),
	}, "\n") + "\n"
	if err := peer.tunnel.Apply(configuration); err != nil {
		t.Fatal(err)
	}
}

func listenPort(t *testing.T, tunnel *Tunnel) int {
	t.Helper()
	configuration, err := tunnel.Configuration()
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
	t.Fatal("running tunnel reported no listen port")
	return 0
}

func randomPrivateKey(t *testing.T) [32]byte {
	t.Helper()
	var key [32]byte
	if _, err := rand.Read(key[:]); err != nil {
		t.Fatal(err)
	}
	key[0] &= 248
	key[31] = (key[31] & 127) | 64
	return key
}

func privateKeyConfiguration(privateKey [32]byte) string {
	return "private_key=" + hex.EncodeToString(privateKey[:]) + "\n"
}

func silentLogger() *device.Logger {
	return device.NewLogger(device.LogLevelSilent, "")
}
