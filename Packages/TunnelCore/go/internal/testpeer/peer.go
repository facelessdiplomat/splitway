package testpeer

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"net/netip"
	"strconv"
	"strings"

	"golang.org/x/crypto/curve25519"
	"golang.zx2c4.com/wireguard/device"
	"golang.zx2c4.com/wireguard/tun/netstack"
	"splitway/tunnelcore/fdtunnel"
)

const (
	EchoPort     = 7
	DiscardPort  = 9
	ClosedPort   = 19
	DNSPort      = 53
	Hostname     = "echo.tunnel.test"
	MTU          = 1420
	keyByteCount = 32
)

var (
	ServerAddress   = netip.MustParseAddr("10.0.0.2")
	ClientAddress   = netip.MustParseAddr("10.0.0.1")
	errNoListenPort = errors.New("test peer reported no listen port")
)

type Peer struct {
	tunnel     *fdtunnel.Tunnel
	servers    *servers
	publicKey  [keyByteCount]byte
	listenPort int
}

func Start(clientPublicKey [keyByteCount]byte, logger *device.Logger) (*Peer, error) {
	privateKey, err := randomPrivateKey()
	if err != nil {
		return nil, err
	}
	publicKey, err := curve25519.X25519(privateKey[:], curve25519.Basepoint)
	if err != nil {
		return nil, err
	}
	tunnelInterface, stack, err := netstack.CreateNetTUN([]netip.Addr{ServerAddress}, nil, MTU)
	if err != nil {
		return nil, err
	}
	tunnel, err := fdtunnel.Start(tunnelInterface, configuration(privateKey, clientPublicKey), logger)
	if err != nil {
		return nil, err
	}
	peer := &Peer{tunnel: tunnel, publicKey: [keyByteCount]byte(publicKey)}
	if peer.listenPort, err = listenPort(tunnel); err != nil {
		tunnel.Stop()
		return nil, err
	}
	if peer.servers, err = startServers(stack); err != nil {
		tunnel.Stop()
		return nil, err
	}
	return peer, nil
}

func (peer *Peer) PublicKey() [keyByteCount]byte {
	return peer.publicKey
}

func (peer *Peer) ListenPort() int {
	return peer.listenPort
}

func (peer *Peer) Stop() {
	peer.servers.stop()
	peer.tunnel.Stop()
}

func ClientPeerConfiguration(peer *Peer) string {
	return strings.Join([]string{
		"replace_peers=true",
		"public_key=" + hex.EncodeToString(peer.publicKey[:]),
		fmt.Sprintf("endpoint=127.0.0.1:%d", peer.listenPort),
		"replace_allowed_ips=true",
		"allowed_ip=" + netip.PrefixFrom(ServerAddress, ServerAddress.BitLen()).String(),
	}, "\n") + "\n"
}

func RandomPrivateKey() ([keyByteCount]byte, error) {
	return randomPrivateKey()
}

func randomPrivateKey() ([keyByteCount]byte, error) {
	var key [keyByteCount]byte
	if _, err := rand.Read(key[:]); err != nil {
		return key, err
	}
	key[0] &= 248
	key[31] = (key[31] & 127) | 64
	return key, nil
}

func configuration(privateKey, clientPublicKey [keyByteCount]byte) string {
	return strings.Join([]string{
		"private_key=" + hex.EncodeToString(privateKey[:]),
		"listen_port=0",
		"replace_peers=true",
		"public_key=" + hex.EncodeToString(clientPublicKey[:]),
		"replace_allowed_ips=true",
		"allowed_ip=" + netip.PrefixFrom(ClientAddress, ClientAddress.BitLen()).String(),
	}, "\n") + "\n"
}

func listenPort(tunnel *fdtunnel.Tunnel) (int, error) {
	configuration, err := tunnel.Configuration()
	if err != nil {
		return 0, err
	}
	for _, line := range strings.Split(configuration, "\n") {
		if value, found := strings.CutPrefix(line, "listen_port="); found {
			return strconv.Atoi(value)
		}
	}
	return 0, errNoListenPort
}
