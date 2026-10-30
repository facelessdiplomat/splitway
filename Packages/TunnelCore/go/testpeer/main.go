package main

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"

	"golang.zx2c4.com/wireguard/device"
	"splitway/tunnelcore/internal/testpeer"
)

type announcement struct {
	PublicKey  string `json:"publicKey"`
	ListenPort int    `json:"listenPort"`
}

var errMalformedClientKey = errors.New("client public key must be 32 bytes in hex")

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	clientPublicKeyText := flag.String("client-public-key", "", "public key of the client in hex")
	flag.Parse()
	clientPublicKey, err := parseKey(*clientPublicKeyText)
	if err != nil {
		return err
	}
	peer, err := testpeer.Start(clientPublicKey, device.NewLogger(device.LogLevelSilent, ""))
	if err != nil {
		return err
	}
	defer peer.Stop()
	publicKey := peer.PublicKey()
	if err := json.NewEncoder(os.Stdout).Encode(announcement{
		PublicKey:  base64.StdEncoding.EncodeToString(publicKey[:]),
		ListenPort: peer.ListenPort(),
	}); err != nil {
		return err
	}
	_, err = io.Copy(io.Discard, os.Stdin)
	return err
}

func parseKey(text string) ([32]byte, error) {
	var key [32]byte
	bytes, err := hex.DecodeString(text)
	if err != nil || len(bytes) != len(key) {
		return key, errMalformedClientKey
	}
	copy(key[:], bytes)
	return key, nil
}
