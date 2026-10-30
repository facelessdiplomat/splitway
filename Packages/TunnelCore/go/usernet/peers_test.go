package usernet

import (
	"encoding/hex"
	"net/netip"
	"testing"

	"golang.org/x/crypto/curve25519"
	"golang.zx2c4.com/wireguard/device"
	"splitway/tunnelcore/internal/testpeer"
)

const testMTU = 1420

type testPair struct {
	client *Network
	peer   *testpeer.Peer
}

func startTestPair(t testing.TB) *testPair {
	t.Helper()
	clientKey, err := testpeer.RandomPrivateKey()
	if err != nil {
		t.Fatal(err)
	}
	clientPublicKey, err := curve25519.X25519(clientKey[:], curve25519.Basepoint)
	if err != nil {
		t.Fatal(err)
	}
	peer, err := testpeer.Start([32]byte(clientPublicKey), silentLogger())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(peer.Stop)
	options := Options{
		Addresses:  []netip.Addr{testpeer.ClientAddress},
		DNSServers: []netip.Addr{testpeer.ServerAddress},
		MTU:        testMTU,
	}
	client, err := Start(options, "private_key="+hex.EncodeToString(clientKey[:])+"\nlisten_port=0\n", silentLogger())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(client.Stop)
	if err := client.Apply(testpeer.ClientPeerConfiguration(peer)); err != nil {
		t.Fatal(err)
	}
	return &testPair{client: client, peer: peer}
}

func silentLogger() *device.Logger {
	return device.NewLogger(device.LogLevelSilent, "")
}
