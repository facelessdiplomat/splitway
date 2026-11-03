package main

import (
	"context"
	"net/netip"
	"strings"
	"time"

	"golang.zx2c4.com/wireguard/device"
	"splitway/tunnelcore/usernet"
)

const addressSeparator = "\n"

func startUserspaceNetwork(configuration, addressesText, dnsServersText string, mtu int) (int32, tunnelStatus) {
	addresses, addressesAreValid := parseAddresses(addressesText)
	dnsServers, dnsServersAreValid := parseAddresses(dnsServersText)
	if !addressesAreValid || !dnsServersAreValid || mtu <= 0 {
		return 0, statusInvalidArgument
	}
	options := usernet.Options{Addresses: addresses, DNSServers: dnsServers, MTU: mtu}
	return startDevice(func(logger *device.Logger) (runningDevice, error) {
		network, err := usernet.Start(options, configuration, logger)
		if err != nil {
			return nil, err
		}
		return network, nil
	}, userspaceStatusOf)
}

func dialTCP(networkHandle int32, addressText string, port uint16, timeoutMilliseconds int) (int32, tunnelStatus) {
	network, status := userspaceNetwork(networkHandle)
	if status != statusOK {
		return 0, status
	}
	address, err := netip.ParseAddr(addressText)
	if err != nil || timeoutMilliseconds <= 0 {
		return 0, statusInvalidArgument
	}
	dialContext, cancel := context.WithTimeout(context.Background(), milliseconds(timeoutMilliseconds))
	defer cancel()
	connection, err := network.DialTCP(dialContext, netip.AddrPortFrom(address, port))
	if err != nil {
		return 0, userspaceStatusOf(err)
	}
	return openConnections.add(connection), statusOK
}

func dialUDP(networkHandle int32, addressText string, port uint16) (int32, tunnelStatus) {
	network, status := userspaceNetwork(networkHandle)
	if status != statusOK {
		return 0, status
	}
	address, err := netip.ParseAddr(addressText)
	if err != nil {
		return 0, statusInvalidArgument
	}
	connection, err := network.DialUDP(netip.AddrPortFrom(address, port))
	if err != nil {
		return 0, userspaceStatusOf(err)
	}
	return openConnections.add(connection), statusOK
}

func lookupHost(networkHandle int32, name string, timeoutMilliseconds int) (string, tunnelStatus) {
	network, status := userspaceNetwork(networkHandle)
	if status != statusOK {
		return "", status
	}
	if name == "" || timeoutMilliseconds <= 0 {
		return "", statusInvalidArgument
	}
	lookupContext, cancel := context.WithTimeout(context.Background(), milliseconds(timeoutMilliseconds))
	defer cancel()
	addresses, err := network.LookupHost(lookupContext, name)
	if err != nil {
		return "", userspaceStatusOf(err)
	}
	texts := make([]string, 0, len(addresses))
	for _, address := range addresses {
		texts = append(texts, address.String())
	}
	return strings.Join(texts, addressSeparator), statusOK
}

func userspaceNetwork(handle int32) (*usernet.Network, tunnelStatus) {
	running, found := runningDevices.value(handle)
	if !found {
		return nil, statusUnknownHandle
	}
	network, isUserspaceNetwork := running.(*usernet.Network)
	if !isUserspaceNetwork {
		return nil, statusInvalidArgument
	}
	return network, statusOK
}

func parseAddresses(text string) ([]netip.Addr, bool) {
	if text == "" {
		return nil, true
	}
	lines := strings.Split(text, addressSeparator)
	addresses := make([]netip.Addr, 0, len(lines))
	for _, line := range lines {
		address, err := netip.ParseAddr(line)
		if err != nil {
			return nil, false
		}
		addresses = append(addresses, address)
	}
	return addresses, true
}

func milliseconds(count int) time.Duration {
	return time.Duration(count) * time.Millisecond
}
