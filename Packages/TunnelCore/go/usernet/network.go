package usernet

import (
	"context"
	"fmt"
	"net/netip"
	"strings"
	"sync"

	"golang.zx2c4.com/wireguard/device"
	"golang.zx2c4.com/wireguard/tun/netstack"
	"splitway/tunnelcore/fdtunnel"
)

type Options struct {
	Addresses  []netip.Addr
	DNSServers []netip.Addr
	MTU        int
}

type Network struct {
	tunnel      *fdtunnel.Tunnel
	stack       *netstack.Net
	connections *connectionRegistry
	stopOnce    sync.Once
}

func Start(options Options, configuration string, logger *device.Logger) (*Network, error) {
	tunnelInterface, stack, err := netstack.CreateNetTUN(options.Addresses, options.DNSServers, options.MTU)
	if err != nil {
		return nil, fmt.Errorf("%w: %w", ErrInterfaceUnavailable, err)
	}
	coalescing, err := newCoalescingDevice(tunnelInterface)
	if err != nil {
		tunnelInterface.Close()
		return nil, fmt.Errorf("%w: %w", ErrInterfaceUnavailable, err)
	}
	tunnel, err := fdtunnel.Start(coalescing, configuration, logger)
	if err != nil {
		return nil, err
	}
	return &Network{tunnel: tunnel, stack: stack, connections: newConnectionRegistry()}, nil
}

func (network *Network) Apply(configuration string) error {
	return network.tunnel.Apply(configuration)
}

func (network *Network) Configuration() (string, error) {
	return network.tunnel.Configuration()
}

func (network *Network) BumpSockets() error {
	return network.tunnel.BumpSockets()
}

func (network *Network) Stop() {
	network.stopOnce.Do(func() {
		network.connections.closeAll()
		network.tunnel.Stop()
	})
}

func (network *Network) DialTCP(dialContext context.Context, destination netip.AddrPort) (*Connection, error) {
	if !network.connections.isAccepting() {
		return nil, ErrNetworkStopped
	}
	stream, err := network.stack.DialContextTCPAddrPort(dialContext, destination)
	if err != nil {
		return nil, fmt.Errorf("%w: %w", ErrDialFailed, err)
	}
	return network.connections.add(stream)
}

func (network *Network) DialUDP(destination netip.AddrPort) (*Connection, error) {
	if !network.connections.isAccepting() {
		return nil, ErrNetworkStopped
	}
	socket, err := network.stack.DialUDPAddrPort(netip.AddrPort{}, destination)
	if err != nil {
		return nil, fmt.Errorf("%w: %w", ErrDialFailed, err)
	}
	return network.connections.add(socket)
}

func (network *Network) LookupHost(lookupContext context.Context, name string) ([]netip.Addr, error) {
	texts, err := network.stack.LookupContextHost(lookupContext, strings.TrimSuffix(name, "."))
	if err != nil {
		return nil, fmt.Errorf("%w: %w", ErrLookupFailed, err)
	}
	addresses := make([]netip.Addr, 0, len(texts))
	for _, text := range texts {
		if address, err := netip.ParseAddr(text); err == nil {
			addresses = append(addresses, address)
		}
	}
	return addresses, nil
}
